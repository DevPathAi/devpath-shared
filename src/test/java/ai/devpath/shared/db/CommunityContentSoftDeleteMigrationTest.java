package ai.devpath.shared.db;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.sql.SQLException;
import java.util.Map;
import java.util.UUID;
import javax.sql.DataSource;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.postgresql.ds.PGSimpleDataSource;

/**
 * 커뮤니티 소프트 삭제 마이그레이션이 <b>기존 행</b>을 보존하고 PUBLISHED 로 백필하는지.
 *
 * <p>같은 파일의 최종 형태 테스트들은 빈 DB 에서 만든 결과만 본다 — 기존 행을 전부
 * DELETED 로 칠하는 마이그레이션도 통과시킨다. {@code SandboxDurableTerminalStateMigrationTest}
 * 의 확립된 패턴(임시 스키마 + baseline + 실데이터)을 따른다.
 *
 * <p>★마이그레이션이 스키마 명시 바인딩({@code to_regclass} 가드)으로 고쳐졌기 때문에 이
 * 테스트가 비로소 가능하다★ — unqualified 였다면 search_path 를 타고 public 을 건드렸다.
 */
class CommunityContentSoftDeleteMigrationTest {

  /** V202608201001 바로 앞 버전. 여기까지 적용된 상태를 baseline 으로 삼는다. */
  private static final String PRIOR_VERSION = "202608161011";

  @Test
  void upgradesPopulatedTablesPreservingRowsAndBackfillingPublished() throws Exception {
    String schema = "community_sd_" + UUID.randomUUID().toString().replace("-", "");
    try {
      try (var c = dataSource().getConnection(); var st = c.createStatement()) {
        st.execute("CREATE SCHEMA " + schema);
        // 마이그레이션 이전 형태의 최소 테이블 — 대상 마이그레이션은 status 만 더하므로
        // 다른 컬럼은 필요 없다.
        st.execute("CREATE TABLE " + schema + ".community_answers ("
            + "id BIGSERIAL PRIMARY KEY, body_md TEXT NOT NULL)");
        st.execute("CREATE TABLE " + schema + ".community_comments ("
            + "id BIGSERIAL PRIMARY KEY, body_md TEXT NOT NULL)");
        st.execute("INSERT INTO " + schema + ".community_answers(body_md) "
            + "VALUES ('legacy-a1'),('legacy-a2')");
        st.execute("INSERT INTO " + schema + ".community_comments(body_md) "
            + "VALUES ('legacy-c1')");
      }

      Flyway.configure()
          .configuration(Map.of("flyway.postgresql.transactional.lock", "false"))
          .dataSource(dataSource())
          .locations("classpath:db/migration")
          .schemas(schema)
          .defaultSchema(schema)
          .baselineOnMigrate(true)
          .baselineVersion(PRIOR_VERSION)
          .placeholderReplacement(false)
          .load()
          .migrate();

      try (var c = dataSource().getConnection(); var st = c.createStatement()) {
        try (var rs = st.executeQuery("SELECT count(*), "
            + "count(*) FILTER (WHERE status = 'PUBLISHED') FROM "
            + schema + ".community_answers")) {
          assertTrue(rs.next());
          assertEquals(2, rs.getInt(1), "기존 답변 행이 보존돼야 한다");
          assertEquals(2, rs.getInt(2), "기존 행은 PUBLISHED 로 백필돼야 한다");
        }
        try (var rs = st.executeQuery("SELECT count(*), "
            + "count(*) FILTER (WHERE status = 'PUBLISHED') FROM "
            + schema + ".community_comments")) {
          assertTrue(rs.next());
          assertEquals(1, rs.getInt(1), "기존 댓글 행이 보존돼야 한다");
          assertEquals(1, rs.getInt(2), "기존 행은 PUBLISHED 로 백필돼야 한다");
        }
        try (var ps = c.prepareStatement("SELECT convalidated FROM pg_constraint "
            + "WHERE conrelid = (? || '.community_answers')::regclass "
            + "AND conname = 'chk_community_answers_status'")) {
          ps.setString(1, schema);
          try (var rs = ps.executeQuery()) {
            assertTrue(rs.next(), "업그레이드 뒤 상태 제약이 있어야 한다");
            assertTrue(rs.getBoolean(1), "기존 행 검증까지 끝나야 한다");
          }
        }
        SQLException bad = assertThrows(SQLException.class, () -> st.execute(
            "INSERT INTO " + schema + ".community_answers(body_md,status) "
                + "VALUES ('x','DRAFT')"));
        assertEquals("23514", bad.getSQLState(), "어휘 밖 값은 CHECK 로 거부돼야 한다");
      }
    } finally {
      dropTemporarySchema(schema);
    }
  }

  /**
   * ★비대칭(한쪽 테이블만 존재)은 조용한 스킵이 아니라 실패여야 한다★ — 조용히 건너뛰면
   * Flyway 가 성공으로 기록해 영영 재시도가 없다(fail-open). 외부 리뷰 지적을 채택한 계약.
   */
  @Test
  void asymmetricCommunityTablesFailInsteadOfSilentlySkipping() throws Exception {
    String schema = "community_sd_" + UUID.randomUUID().toString().replace("-", "");
    try {
      try (var c = dataSource().getConnection(); var st = c.createStatement()) {
        st.execute("CREATE SCHEMA " + schema);
        st.execute("CREATE TABLE " + schema + ".community_answers ("
            + "id BIGSERIAL PRIMARY KEY, body_md TEXT NOT NULL)");
        // community_comments 는 일부러 만들지 않는다 — 드리프트 시나리오.
      }

      Throwable failure = assertThrows(Throwable.class, () -> Flyway.configure()
          .configuration(Map.of("flyway.postgresql.transactional.lock", "false"))
          .dataSource(dataSource())
          .locations("classpath:db/migration")
          .schemas(schema)
          .defaultSchema(schema)
          .baselineOnMigrate(true)
          .baselineVersion(PRIOR_VERSION)
          .placeholderReplacement(false)
          .load()
          .migrate());

      boolean mentionsAsymmetry = false;
      for (Throwable t = failure; t != null; t = t.getCause()) {
        if (String.valueOf(t.getMessage()).contains("asymmetric community tables")) {
          mentionsAsymmetry = true;
          break;
        }
      }
      assertTrue(mentionsAsymmetry,
          "비대칭은 우리가 세운 예외로 실패해야 한다(다른 이유의 실패면 오독): " + failure);
    } finally {
      dropTemporarySchema(schema);
    }
  }

  private static void dropTemporarySchema(String schema) throws Exception {
    if (!schema.matches("community_sd_[a-f0-9]{32}")) {
      throw new IllegalArgumentException("refusing to drop unexpected schema: " + schema);
    }
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      st.execute("DROP SCHEMA IF EXISTS " + schema + " CASCADE");
    }
  }

  private static DataSource dataSource() {
    PGSimpleDataSource ds = new PGSimpleDataSource();
    ds.setUrl(System.getenv().getOrDefault("DB_URL",
        "jdbc:postgresql://localhost:5432/devpath"));
    ds.setUser(System.getenv().getOrDefault("DB_USER", "devpath"));
    ds.setPassword(System.getenv().getOrDefault("DB_PASSWORD", "localdev"));
    return ds;
  }
}

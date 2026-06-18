package ai.devpath.shared.db;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import javax.sql.DataSource;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.postgresql.ds.PGSimpleDataSource;

/**
 * 중앙 Flyway 마이그레이션 검증.
 * 로컬은 docker-compose의 postgres(5432), CI는 postgres service container에 연결한다.
 * 연결 정보는 DB_URL/DB_USER/DB_PASSWORD 환경변수로 주입한다 (기본은 로컬 compose).
 * 이미 적용된 DB에 대해서도 멱등하게 통과하도록 "결과 상태"(함수 존재)를 검증한다.
 */
class FlywayMigrationTest {

  private static DataSource dataSource() {
    PGSimpleDataSource ds = new PGSimpleDataSource();
    ds.setUrl(System.getenv().getOrDefault("DB_URL", "jdbc:postgresql://localhost:5432/devpath"));
    ds.setUser(System.getenv().getOrDefault("DB_USER", "devpath"));
    ds.setPassword(System.getenv().getOrDefault("DB_PASSWORD", "localdev"));
    return ds;
  }

  @Test
  void migrationsApplyAndCommonFunctionExists() throws Exception {
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
    try (var c = dataSource().getConnection();
        var st = c.createStatement();
        var rs = st.executeQuery("SELECT proname FROM pg_proc WHERE proname = 'set_updated_at'")) {
      assertTrue(rs.next(), "set_updated_at 함수가 존재해야 한다 (공통 규약 마이그레이션)");
    }
  }

  @Test
  void usersAndDormantArchivesExist() throws Exception {
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
    try (var c = dataSource().getConnection();
        var rs = c.getMetaData().getTables(null, "public", "%", new String[] {"TABLE"})) {
      var names = new java.util.HashSet<String>();
      while (rs.next()) names.add(rs.getString("TABLE_NAME"));
      assertTrue(names.contains("users"), "users 테이블 필요");
      assertTrue(names.contains("dormant_user_archives"), "dormant_user_archives 테이블 필요");
    }
  }

  private static java.util.Set<String> columns(String table) throws Exception {
    try (var c = dataSource().getConnection();
        var rs = c.getMetaData().getColumns(null, "public", table, "%")) {
      var cols = new java.util.HashSet<String>();
      while (rs.next()) cols.add(rs.getString("COLUMN_NAME"));
      return cols;
    }
  }

  @Test
  void usersHasAuthColumnsAndDropsGithubId() throws Exception {
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
    var cols = columns("users");
    assertTrue(cols.contains("email"), "users.email 필요");
    assertTrue(cols.contains("nickname"), "users.nickname 필요");
    assertTrue(cols.contains("role"), "users.role 필요");
    assertTrue(cols.contains("onboarding_status"), "users.onboarding_status 필요");
    assertFalse(cols.contains("github_id"), "users.github_id 제거(신원 이관)");
  }

  @Test
  void oauthIdentitiesTableExists() throws Exception {
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
    try (var c = dataSource().getConnection();
        var rs = c.getMetaData().getTables(null, "public", "user_oauth_identities", new String[] {"TABLE"})) {
      assertTrue(rs.next(), "user_oauth_identities 테이블 필요");
    }
  }

  @Test
  void userProfilesTableExists() throws Exception {
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
    try (var c = dataSource().getConnection();
        var rs = c.getMetaData().getTables(null, "public", "user_profiles", new String[] {"TABLE"})) {
      assertTrue(rs.next(), "user_profiles 테이블 필요");
    }
  }

  @Test
  void outboxTableExists() throws Exception {
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
    try (var c = dataSource().getConnection();
        var rs = c.getMetaData().getTables(null, "public", "outbox", new String[] {"TABLE"})) {
      assertTrue(rs.next(), "outbox 테이블 필요");
    }
  }

  @Test
  void notificationsTableExists() throws Exception {
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
    try (var c = dataSource().getConnection();
        var rs = c.getMetaData().getTables(null, "public", "notifications", new String[] {"TABLE"})) {
      assertTrue(rs.next(), "notifications 테이블 필요");
    }
  }

  @Test
  void questionBankTableExists() throws Exception {
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
    try (var c = dataSource().getConnection();
        var rs = c.getMetaData().getTables(null, "public", "question_bank", new String[] {"TABLE"})) {
      assertTrue(rs.next(), "question_bank 테이블 필요");
    }
  }

  @Test
  void assessmentsTableExists() throws Exception {
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
    try (var c = dataSource().getConnection();
        var rs = c.getMetaData().getTables(null, "public", "assessments", new String[] {"TABLE"})) {
      assertTrue(rs.next(), "assessments 테이블 필요");
    }
  }

  @Test
  void assessmentItemsTableExists() throws Exception {
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
    try (var c = dataSource().getConnection();
        var rs = c.getMetaData().getTables(null, "public", "assessment_items", new String[] {"TABLE"})) {
      assertTrue(rs.next(), "assessment_items 테이블 필요");
    }
  }

  @Test
  void assessmentResultsTableExists() throws Exception {
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
    try (var c = dataSource().getConnection();
        var rs = c.getMetaData().getTables(null, "public", "assessment_results", new String[] {"TABLE"})) {
      assertTrue(rs.next(), "assessment_results 테이블 필요");
    }
  }

  @Test
  void questionBankRejectsBadEnumAndRange() throws Exception {
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      assertThrows(java.sql.SQLException.class, () ->
        st.execute("INSERT INTO question_bank(track,question_type,content,answer_key,bloom_level,difficulty) "
          + "VALUES ('BACKEND_SPRING','MCQ','q','{}','NOPE',0.3)"));
      assertThrows(java.sql.SQLException.class, () ->
        st.execute("INSERT INTO question_bank(track,question_type,content,answer_key,bloom_level,difficulty) "
          + "VALUES ('BACKEND_SPRING','MCQ','q','{}','APPLY',9.9)"));
    }
  }

  @Test
  void assessmentsHasNoUserFk() throws Exception {
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      // user_id 교차서비스 FK 제거(서비스 경계): 존재하지 않는 user_id로도 INSERT 가능해야 한다.
      st.execute("INSERT INTO assessments(user_id, track) VALUES (999999999, 'BACKEND_SPRING')");
      st.execute("DELETE FROM assessments WHERE user_id = 999999999");
    }
  }
}

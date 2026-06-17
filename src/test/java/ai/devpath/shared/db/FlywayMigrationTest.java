package ai.devpath.shared.db;

import static org.junit.jupiter.api.Assertions.assertFalse;
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
}

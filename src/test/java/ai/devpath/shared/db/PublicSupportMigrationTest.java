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

/** 공개 Home 문의와 인증 앱 문의가 같은 지원 큐를 안전하게 공유하는 DB 계약. */
class PublicSupportMigrationTest {

  private static final String PRIOR_VERSION = "202608221001";

  @Test
  void preservesAuthenticatedRowsAndAllowsOnlyCompletePublicRows() throws Exception {
    String schema = "public_support_" + UUID.randomUUID().toString().replace("-", "");
    try {
      createPriorSupportTable(schema);

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
        try (var rs = st.executeQuery("SELECT reporter_id,source,contact_email,"
            + "privacy_consent_at FROM " + schema + ".support_requests WHERE id=1")) {
          assertTrue(rs.next());
          assertEquals(42L, rs.getLong("reporter_id"));
          assertEquals("AUTHENTICATED_APP", rs.getString("source"));
          assertEquals(null, rs.getString("contact_email"));
          assertEquals(null, rs.getTimestamp("privacy_consent_at"));
        }

        assertEquals(1, st.executeUpdate("INSERT INTO " + schema
            + ".support_requests(reporter_id,source,contact_email,privacy_consent_at,type,title,body) "
            + "VALUES(NULL,'PUBLIC_HOME','person@example.com',now(),'INQUIRY','질문','본문')"));

        assertCheckViolation(st, "INSERT INTO " + schema
            + ".support_requests(reporter_id,source,type,title,body) "
            + "VALUES(NULL,'AUTHENTICATED_APP','ERROR','x','x')");
        assertCheckViolation(st, "INSERT INTO " + schema
            + ".support_requests(reporter_id,source,contact_email,privacy_consent_at,type,title,body) "
            + "VALUES(42,'PUBLIC_HOME','person@example.com',now(),'ERROR','x','x')");
        assertCheckViolation(st, "INSERT INTO " + schema
            + ".support_requests(reporter_id,source,contact_email,type,title,body) "
            + "VALUES(NULL,'PUBLIC_HOME','person@example.com','ERROR','x','x')");
        assertCheckViolation(st, "INSERT INTO " + schema
            + ".support_requests(reporter_id,source,contact_email,privacy_consent_at,type,title,body) "
            + "VALUES(NULL,'OTHER','person@example.com',now(),'ERROR','x','x')");

        try (var rs = st.executeQuery("SELECT is_nullable FROM information_schema.columns "
            + "WHERE table_schema='" + schema + "' AND table_name='support_requests' "
            + "AND column_name='reporter_id'")) {
          assertTrue(rs.next());
          assertEquals("YES", rs.getString(1));
        }
      }
    } finally {
      dropSchema(schema);
    }
  }

  private static void createPriorSupportTable(String schema) throws Exception {
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      st.execute("CREATE SCHEMA " + schema);
      st.execute("CREATE TABLE " + schema + ".support_requests ("
          + "id BIGSERIAL PRIMARY KEY, reporter_id BIGINT NOT NULL,"
          + "type VARCHAR(16) NOT NULL, title VARCHAR(200) NOT NULL, body TEXT NOT NULL,"
          + "status VARCHAR(16) NOT NULL DEFAULT 'OPEN', created_at TIMESTAMPTZ NOT NULL DEFAULT now())");
      st.execute("INSERT INTO " + schema
          + ".support_requests(reporter_id,type,title,body) VALUES(42,'ERROR','legacy','body')");
    }
  }

  private static void assertCheckViolation(java.sql.Statement statement, String sql) {
    SQLException violation = assertThrows(SQLException.class, () -> statement.execute(sql));
    assertEquals("23514", violation.getSQLState());
  }

  private static void dropSchema(String schema) throws Exception {
    if (!schema.matches("public_support_[a-f0-9]{32}")) {
      throw new IllegalArgumentException("refusing to drop unexpected schema: " + schema);
    }
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      st.execute("DROP SCHEMA IF EXISTS " + schema + " CASCADE");
    }
  }

  private static DataSource dataSource() {
    PGSimpleDataSource ds = new PGSimpleDataSource();
    ds.setUrl(System.getenv().getOrDefault("DB_URL", "jdbc:postgresql://localhost:5432/devpath"));
    ds.setUser(System.getenv().getOrDefault("DB_USER", "devpath"));
    ds.setPassword(System.getenv().getOrDefault("DB_PASSWORD", "localdev"));
    return ds;
  }
}

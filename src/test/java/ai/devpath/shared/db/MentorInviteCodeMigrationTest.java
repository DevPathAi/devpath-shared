package ai.devpath.shared.db;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.sql.SQLException;
import java.util.Map;
import java.util.UUID;
import javax.sql.DataSource;
import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.FlywayException;
import org.junit.jupiter.api.Test;
import org.postgresql.ds.PGSimpleDataSource;

class MentorInviteCodeMigrationTest {
  private static final String PRIOR_VERSION = "202609051002";

  @Test
  void storesOnlyHashedCodesAndConstrainsRedemptions() throws Exception {
    String schema = "mentor_code_" + UUID.randomUUID().toString().replace("-", "");
    try {
      createPriorTables(schema);
      migrate(schema);

      try (var c = dataSource().getConnection(); var st = c.createStatement()) {
        try (var rs = st.executeQuery("SELECT column_name FROM information_schema.columns "
            + "WHERE table_schema='" + schema + "' AND table_name='mentor_invite_codes'")) {
          boolean hasHash = false;
          boolean hasRaw = false;
          while (rs.next()) {
            String column = rs.getString(1);
            hasHash |= "code_hash".equals(column);
            hasRaw |= column.contains("raw") || "code".equals(column);
          }
          assertTrue(hasHash);
          assertFalse(hasRaw);
        }

        assertEquals(1, st.executeUpdate("INSERT INTO " + schema
            + ".mentor_invite_codes(code_hash,label,audience,cohort,expires_at,max_redemptions,created_by) "
            + "VALUES('" + "a".repeat(64) + "','2기 심사','JUDGE','cohort-2',now()+interval '1 day',1,1)"));
        assertCheckViolation(st, "INSERT INTO " + schema
            + ".mentor_invite_codes(code_hash,label,audience,cohort,expires_at,max_redemptions,created_by) "
            + "VALUES('short','x','JUDGE','c',now()+interval '1 day',1,1)");
        assertCheckViolation(st, "UPDATE " + schema
            + ".mentor_invite_codes SET redemption_count=2 WHERE code_hash='" + "a".repeat(64) + "'");

        assertEquals(1, st.executeUpdate("INSERT INTO " + schema
            + ".mentor_invite_code_redemptions(invite_code_id,user_id) VALUES(1,2)"));
        assertThrows(SQLException.class, () -> st.execute("INSERT INTO " + schema
            + ".mentor_invite_code_redemptions(invite_code_id,user_id) VALUES(1,2)"));
      }
    } finally {
      dropSchema(schema);
    }
  }

  @Test
  void failsWithoutRecordingMigrationWhenMentorAccessIsMissing() throws Exception {
    String schema = "mentor_code_" + UUID.randomUUID().toString().replace("-", "");
    try {
      try (var c = dataSource().getConnection(); var st = c.createStatement()) {
        st.execute("CREATE SCHEMA " + schema);
        st.execute("CREATE TABLE " + schema + ".users (id BIGINT PRIMARY KEY)");
      }

      assertThrows(FlywayException.class, () -> migrate(schema));
      assertMigrationNotRecorded(schema, "202609051003");
    } finally {
      dropSchema(schema);
    }
  }

  private static void migrate(String schema) {
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
  }

  private static void createPriorTables(String schema) throws Exception {
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      st.execute("CREATE SCHEMA " + schema);
      st.execute("CREATE TABLE " + schema + ".users (id BIGINT PRIMARY KEY)");
      st.execute("INSERT INTO " + schema + ".users VALUES(1),(2)");
      st.execute("CREATE TABLE " + schema + ".mentor_access ("
          + "id BIGSERIAL PRIMARY KEY,user_id BIGINT NOT NULL UNIQUE REFERENCES " + schema
          + ".users(id),status VARCHAR(16) NOT NULL,source VARCHAR(16) NOT NULL,"
          + "waitlisted_at TIMESTAMPTZ NOT NULL,activated_at TIMESTAMPTZ,"
          + "batch_id BIGINT,invite_code_id BIGINT)");
    }
  }

  private static void assertCheckViolation(java.sql.Statement statement, String sql) {
    SQLException violation = assertThrows(SQLException.class, () -> statement.execute(sql));
    assertEquals("23514", violation.getSQLState());
  }

  private static void assertMigrationNotRecorded(String schema, String version) throws Exception {
    try (var c = dataSource().getConnection(); var st = c.createStatement();
         var rs = st.executeQuery("SELECT count(*) FROM " + schema
             + ".flyway_schema_history WHERE version='" + version + "' AND success")) {
      assertTrue(rs.next());
      assertEquals(0, rs.getInt(1));
    }
  }

  private static void dropSchema(String schema) throws Exception {
    if (!schema.matches("mentor_code_[a-f0-9]{32}")) {
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

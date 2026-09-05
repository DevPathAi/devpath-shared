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

class MentorAccessMigrationTest {

  private static final String PRIOR_VERSION = "202609051001";

  @Test
  void backfillsApprovedUsersAndKeepsUnapprovedUsersOutOfMentorAccess() throws Exception {
    String schema = "mentor_access_" + UUID.randomUUID().toString().replace("-", "");
    try {
      createPriorTables(schema);

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
        try (var rs = st.executeQuery("SELECT user_id,status,source,activated_at "
            + "FROM " + schema + ".mentor_access ORDER BY user_id")) {
          assertTrue(rs.next());
          assertEquals(1L, rs.getLong("user_id"));
          assertEquals("ACTIVE", rs.getString("status"));
          assertEquals("ADMIN", rs.getString("source"));
          assertTrue(rs.getTimestamp("activated_at") != null);
          assertTrue(!rs.next());
        }

        assertEquals(1, st.executeUpdate("INSERT INTO " + schema
            + ".mentor_access(user_id,status,source,waitlisted_at) "
            + "VALUES(2,'WAITLISTED','SELF',now())"));
        assertCheckViolation(st, "INSERT INTO " + schema
            + ".mentor_access(user_id,status,source,waitlisted_at,activated_at) "
            + "VALUES(3,'WAITLISTED','SELF',now(),now())");
        assertCheckViolation(st, "INSERT INTO " + schema
            + ".mentor_access(user_id,status,source,waitlisted_at) "
            + "VALUES(3,'ACTIVE','BATCH',now())");
      }
    } finally {
      dropSchema(schema);
    }
  }

  private static void createPriorTables(String schema) throws Exception {
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      st.execute("CREATE SCHEMA " + schema);
      st.execute("CREATE TABLE " + schema + ".users ("
          + "id BIGINT PRIMARY KEY, email VARCHAR(255), status VARCHAR(20) NOT NULL)");
      st.execute("CREATE TABLE " + schema + ".beta_allowlist ("
          + "id BIGSERIAL PRIMARY KEY, email VARCHAR(320) NOT NULL UNIQUE)");
      st.execute("INSERT INTO " + schema + ".users VALUES"
          + "(1,'Approved@Example.com','ACTIVE'),(2,'waiting@example.com','ACTIVE'),"
          + "(3,'inactive@example.com','DELETED')");
      st.execute("INSERT INTO " + schema
          + ".beta_allowlist(email) VALUES('approved@example.com'),('inactive@example.com')");
    }
  }

  private static void assertCheckViolation(java.sql.Statement statement, String sql) {
    SQLException violation = assertThrows(SQLException.class, () -> statement.execute(sql));
    assertEquals("23514", violation.getSQLState());
  }

  private static void dropSchema(String schema) throws Exception {
    if (!schema.matches("mentor_access_[a-f0-9]{32}")) {
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

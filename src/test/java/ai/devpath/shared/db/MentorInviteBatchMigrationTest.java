package ai.devpath.shared.db;

import static org.junit.jupiter.api.Assertions.assertEquals;
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

class MentorInviteBatchMigrationTest {
  private static final String PRIOR_VERSION = "202609051003";

  @Test
  void oneBatchPerDayAndOneDeliveryPerActivationAreDatabaseInvariants() throws Exception {
    String schema = "mentor_batch_" + UUID.randomUUID().toString().replace("-", "");
    try {
      createPriorTables(schema);
      migrate(schema);

      try (var c = dataSource().getConnection(); var st = c.createStatement()) {
        assertEquals(1, st.executeUpdate("INSERT INTO " + schema
            + ".mentor_invite_batches(batch_date,status,chunk_size,daily_cap) "
            + "VALUES('2026-09-05','RUNNING',25,100)"));
        assertThrows(SQLException.class, () -> st.execute("INSERT INTO " + schema
            + ".mentor_invite_batches(batch_date,status,chunk_size,daily_cap) "
            + "VALUES('2026-09-05','RUNNING',25,100)"));

        String eventId = UUID.randomUUID().toString();
        assertEquals(1, st.executeUpdate("INSERT INTO " + schema
            + ".mentor_invite_deliveries(event_id,user_id,batch_id,provider_message_id) "
            + "VALUES('" + eventId + "',1,1,'provider-1')"));
        assertThrows(SQLException.class, () -> st.execute("INSERT INTO " + schema
            + ".mentor_invite_deliveries(event_id,user_id,batch_id,provider_message_id) "
            + "VALUES('" + eventId + "',1,1,'provider-duplicate')"));
      }
    } finally {
      dropSchema(schema);
    }
  }

  @Test
  void failsWithoutRecordingMigrationWhenMentorAccessIsMissing() throws Exception {
    String schema = "mentor_batch_" + UUID.randomUUID().toString().replace("-", "");
    try {
      try (var c = dataSource().getConnection(); var st = c.createStatement()) {
        st.execute("CREATE SCHEMA " + schema);
        st.execute("CREATE TABLE " + schema + ".users (id BIGINT PRIMARY KEY)");
      }

      assertThrows(FlywayException.class, () -> migrate(schema));
      assertMigrationNotRecorded(schema, "202609051004");
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
      st.execute("INSERT INTO " + schema + ".users VALUES(1)");
      st.execute("CREATE TABLE " + schema + ".mentor_access ("
          + "id BIGSERIAL PRIMARY KEY,user_id BIGINT NOT NULL UNIQUE REFERENCES " + schema
          + ".users(id),status VARCHAR(16) NOT NULL,source VARCHAR(16) NOT NULL,"
          + "waitlisted_at TIMESTAMPTZ NOT NULL,activated_at TIMESTAMPTZ,"
          + "batch_id BIGINT,invite_code_id BIGINT,version BIGINT NOT NULL DEFAULT 0)");
    }
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
    if (!schema.matches("mentor_batch_[a-f0-9]{32}")) {
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

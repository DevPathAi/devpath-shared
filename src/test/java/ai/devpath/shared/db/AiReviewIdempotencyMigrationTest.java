package ai.devpath.shared.db;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import javax.sql.DataSource;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.postgresql.ds.PGSimpleDataSource;

/** ET8 Review at-least-once consumer idempotency schema contract. */
class AiReviewIdempotencyMigrationTest {

  private static final String PRIOR_VERSION = "202608151003";

  @Test
  void phaseOneAddsLeaseAndInboxWithoutReplacingTheValidatedLegacyStatusGuard()
      throws Exception {
    String schema = temporarySchemaName();
    try {
      createPriorSchema(schema);

      migrate(schema, "202608161003");

      try (var c = dataSource().getConnection()) {
        Map<String, Boolean> constraints = constraints(c, schema);
        assertEquals(Boolean.TRUE, constraints.get("chk_ai_review_status"));
        assertEquals(Boolean.FALSE, constraints.get("chk_ai_review_status_v2"));
        assertEquals(Boolean.FALSE, constraints.get("chk_ai_review_processing_lease"));

        var columns = columns(c, schema, "ai_code_reviews");
        assertTrue(columns.containsKey("processing_token"));
        assertTrue(columns.containsKey("lease_expires_at"));
        assertTrue(columns.containsKey("source_event_id"));

        try (var rs = c.getMetaData().getTables(null, schema, "ai_review_event_inbox",
            new String[] {"TABLE"})) {
          assertTrue(rs.next(), "durable eventId inbox table must exist");
        }
      }
    } finally {
      dropSchema(schema);
    }
  }

  @Test
  void finalPhasePreservesRowsAndEnforcesProcessingLeaseAndDurableInbox()
      throws Exception {
    String schema = temporarySchemaName();
    UUID eventId = UUID.randomUUID();
    try {
      createPriorSchema(schema);
      migrate(schema, null);

      try (var c = dataSource().getConnection(); var st = c.createStatement()) {
        Map<String, Boolean> constraints = constraints(c, schema);
        assertEquals(Boolean.TRUE, constraints.get("chk_ai_review_status"));
        assertEquals(Boolean.TRUE, constraints.get("chk_ai_review_processing_lease"));
        assertFalse(constraints.containsKey("chk_ai_review_status_v2"));

        try (var rs = st.executeQuery("SELECT status FROM " + schema
            + ".ai_code_reviews WHERE sandbox_session_id=7001")) {
          assertTrue(rs.next(), "legacy review row must be preserved");
          assertEquals("PENDING", rs.getString(1));
        }

        st.execute("UPDATE " + schema + ".ai_code_reviews SET status='PROCESSING', "
            + "processing_token='" + UUID.randomUUID() + "', lease_expires_at=now() "
            + "WHERE sandbox_session_id=7001");

        assertThrows(SQLException.class, () -> st.execute("UPDATE " + schema
            + ".ai_code_reviews SET processing_token=NULL WHERE sandbox_session_id=7001"));

        st.execute("INSERT INTO " + schema + ".ai_review_event_inbox"
            + "(event_id,sandbox_session_id) VALUES ('" + eventId + "',7001)");
        assertThrows(SQLException.class, () -> st.execute("INSERT INTO " + schema
            + ".ai_review_event_inbox(event_id,sandbox_session_id) VALUES ('"
            + eventId + "',7001)"));

        try (var rs = st.executeQuery("SELECT 1 FROM pg_indexes WHERE schemaname='"
            + schema + "' AND indexname='idx_ai_reviews_processing_lease'")) {
          assertTrue(rs.next(), "expired processing claims need a bounded lookup index");
        }
        try (var rs = st.executeQuery("SELECT 1 FROM pg_indexes WHERE schemaname='"
            + schema + "' AND indexname='idx_ai_review_inbox_session'")) {
          assertTrue(rs.next(), "session-correlated inbox lookup needs an index");
        }
      }
    } finally {
      dropSchema(schema);
    }
  }

  private static void createPriorSchema(String schema) throws Exception {
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      st.execute("CREATE SCHEMA " + schema);
      // The review migration follows the sandbox lease migrations in the same
      // Flyway history. Recreate their prior-version prerequisites so this
      // partial-schema test exercises the production migration order.
      st.execute("CREATE TABLE " + schema + ".sandbox_sessions ("
          + "id BIGSERIAL PRIMARY KEY, user_id BIGINT NOT NULL, "
          + "status VARCHAR(16) NOT NULL, started_at TIMESTAMPTZ NOT NULL DEFAULT now(), "
          + "finished_at TIMESTAMPTZ, exit_code INT, stderr TEXT, "
          + "updated_at TIMESTAMPTZ NOT NULL DEFAULT now())");
      st.execute("CREATE TABLE " + schema + ".outbox (id BIGSERIAL PRIMARY KEY)");
      st.execute("CREATE TABLE " + schema + ".ai_code_reviews ("
          + "id BIGSERIAL PRIMARY KEY, sandbox_session_id BIGINT NOT NULL, "
          + "user_id BIGINT NOT NULL, content_id BIGINT, "
          + "status VARCHAR(16) NOT NULL DEFAULT 'PENDING', provider VARCHAR(16), "
          + "confidence INT, strengths JSONB NOT NULL DEFAULT '[]', "
          + "improvements JSONB NOT NULL DEFAULT '[]', security JSONB NOT NULL DEFAULT '[]', "
          + "feedback VARCHAR(8), error_code VARCHAR(32), "
          + "created_at TIMESTAMPTZ NOT NULL DEFAULT now(), "
          + "updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), "
          + "CONSTRAINT uq_ai_code_reviews_session UNIQUE(sandbox_session_id), "
          + "CONSTRAINT chk_ai_review_status CHECK(status IN ('PENDING','DONE','FAILED')))" );
      st.execute("INSERT INTO " + schema
          + ".ai_code_reviews(sandbox_session_id,user_id,status) VALUES(7001,42,'PENDING')");
    }
  }

  private static void migrate(String schema, String target) {
    var config = Flyway.configure()
        .configuration(Map.of("flyway.postgresql.transactional.lock", "false"))
        .dataSource(dataSource())
        .locations("classpath:db/migration")
        .schemas(schema)
        .defaultSchema(schema)
        .baselineOnMigrate(true)
        .baselineVersion(PRIOR_VERSION)
        .placeholderReplacement(false);
    if (target != null) config.target(target);
    config.load().migrate();
  }

  private static Map<String, Boolean> constraints(java.sql.Connection c, String schema)
      throws Exception {
    try (var ps = c.prepareStatement(
        "SELECT conname,convalidated FROM pg_constraint "
            + "WHERE conrelid=(? || '.ai_code_reviews')::regclass")) {
      ps.setString(1, schema);
      Map<String, Boolean> result = new HashMap<>();
      try (var rs = ps.executeQuery()) {
        while (rs.next()) result.put(rs.getString(1), rs.getBoolean(2));
      }
      return result;
    }
  }

  private static Map<String, Integer> columns(java.sql.Connection c, String schema, String table)
      throws Exception {
    Map<String, Integer> result = new HashMap<>();
    try (var rs = c.getMetaData().getColumns(null, schema, table, "%")) {
      while (rs.next()) result.put(rs.getString("COLUMN_NAME"), rs.getInt("DATA_TYPE"));
    }
    return result;
  }

  private static String temporarySchemaName() {
    return "ai_review_et8_" + UUID.randomUUID().toString().replace("-", "");
  }

  private static void dropSchema(String schema) throws Exception {
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

package ai.devpath.shared.db;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
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

/** ET8 lease, mixed-version admission, and terminal-outbox idempotency contract. */
class SandboxLeaseAndAdmissionMigrationTest {

  private static final String PRIOR_VERSION = "202608151003";

  @Test
  void phaseOneAddsNullableLeaseColumnsAndNormalizesExistingActiveDuplicates()
      throws Exception {
    String schema = temporarySchemaName();
    try {
      createPriorSchema(schema);
      migrate(schema, "202608161001");

      try (var c = dataSource().getConnection()) {
        Map<String, String> nullability = new HashMap<>();
        try (var ps = c.prepareStatement(
            "SELECT column_name,is_nullable FROM information_schema.columns "
                + "WHERE table_schema = ? AND table_name = 'sandbox_sessions' "
                + "AND column_name IN ('owner_instance','lease_expires_at')")) {
          ps.setString(1, schema);
          try (var rs = ps.executeQuery()) {
            while (rs.next()) nullability.put(rs.getString(1), rs.getString(2));
          }
        }
        assertEquals(Map.of("owner_instance", "YES", "lease_expires_at", "YES"), nullability,
            "old writers must remain compatible while new writers start populating leases");

        try (var st = c.createStatement();
            var rs = st.executeQuery(
                "SELECT status,finished_at,exit_code FROM " + schema
                    + ".sandbox_sessions WHERE user_id = 8001 ORDER BY id")) {
          assertTrue(rs.next());
          assertEquals("KILLED", rs.getString("status"));
          assertNotNull(rs.getObject("finished_at"));
          assertEquals(-1, rs.getInt("exit_code"));
          assertTrue(rs.next());
          assertEquals("RUNNING", rs.getString("status"));
          assertFalse(rs.next());
        }

        try (var ps = c.prepareStatement(
            "SELECT is_nullable FROM information_schema.columns WHERE table_schema = ? "
                + "AND table_name = 'outbox' AND column_name = 'dedupe_key'")) {
          ps.setString(1, schema);
          try (var rs = ps.executeQuery()) {
            assertTrue(rs.next());
            assertEquals("YES", rs.getString(1));
          }
        }
      }
    } finally {
      dropTemporarySchema(schema);
    }
  }

  @Test
  void phaseTwoEnforcesOneActiveRunAndIdempotentTerminalOutboxWithPartialIndexes()
      throws Exception {
    String schema = temporarySchemaName();
    try {
      createPriorSchema(schema);
      migrate(schema, "202608161002");

      try (var c = dataSource().getConnection(); var st = c.createStatement()) {
        SQLException duplicateActive = assertThrows(SQLException.class, () -> st.execute(
            "INSERT INTO " + schema + ".sandbox_sessions"
                + "(user_id,language,status,submitted_code) "
                + "VALUES (8001,'PYTHON','ALLOCATING','print(2)')"));
        assertEquals("23505", duplicateActive.getSQLState());

        st.execute("INSERT INTO " + schema + ".sandbox_sessions"
            + "(user_id,language,status,submitted_code,finished_at) "
            + "VALUES (8001,'PYTHON','COMPLETED','print(3)',now())");

        st.execute("INSERT INTO " + schema + ".outbox"
            + "(aggregate_type,aggregate_id,event_type,payload,dedupe_key) VALUES "
            + "('sandbox_session','42','sandbox.run.submitted','{}','sandbox.run.submitted:42')");
        SQLException duplicateOutbox = assertThrows(SQLException.class, () -> st.execute(
            "INSERT INTO " + schema + ".outbox"
                + "(aggregate_type,aggregate_id,event_type,payload,dedupe_key) VALUES "
                + "('sandbox_session','42','sandbox.run.submitted','{}',"
                + "'sandbox.run.submitted:42')"));
        assertEquals("23505", duplicateOutbox.getSQLState());

        Map<String, String> indexes = new HashMap<>();
        try (var ps = c.prepareStatement(
            "SELECT indexname,indexdef FROM pg_indexes WHERE schemaname = ? "
                + "AND indexname IN ('uq_sandbox_one_active_user',"
                + "'idx_sandbox_active_lease','idx_sandbox_active_legacy',"
                + "'uq_outbox_dedupe_key')")) {
          ps.setString(1, schema);
          try (var rs = ps.executeQuery()) {
            while (rs.next()) indexes.put(rs.getString(1), rs.getString(2));
          }
        }
        assertEquals(4, indexes.size());
        assertTrue(indexes.get("uq_sandbox_one_active_user").contains("WHERE"));
        assertTrue(indexes.get("idx_sandbox_active_lease").contains("lease_expires_at"));
        assertTrue(indexes.get("idx_sandbox_active_legacy").contains("updated_at"));
        assertTrue(indexes.get("uq_outbox_dedupe_key").contains("dedupe_key"));
      }
    } finally {
      dropTemporarySchema(schema);
    }
  }

  @Test
  void terminalReconciliationFenceIsAdditiveAndRejectsUnknownSources() throws Exception {
    String schema = temporarySchemaName();
    try {
      createPriorSchema(schema);
      migrate(schema, "202608161007");

      try (var c = dataSource().getConnection()) {
        Map<String, String> columns = new HashMap<>();
        try (var ps = c.prepareStatement(
            "SELECT column_name,data_type FROM information_schema.columns "
                + "WHERE table_schema = ? AND table_name = 'sandbox_sessions' "
                + "AND column_name IN ('reconciliation_token',"
                + "'reconciliation_started_at','terminal_source')")) {
          ps.setString(1, schema);
          try (var rs = ps.executeQuery()) {
            while (rs.next()) columns.put(rs.getString(1), rs.getString(2));
          }
        }
        assertEquals("uuid", columns.get("reconciliation_token"));
        assertEquals("timestamp with time zone", columns.get("reconciliation_started_at"));
        assertEquals("character varying", columns.get("terminal_source"));

        try (var st = c.createStatement()) {
          st.execute("INSERT INTO " + schema + ".sandbox_sessions"
              + "(user_id,language,status,submitted_code,terminal_source) VALUES "
              + "(8101,'PYTHON','RUNNING','old','RUNNER')");
          SQLException invalid = assertThrows(SQLException.class, () -> st.execute(
              "UPDATE " + schema + ".sandbox_sessions "
                  + "SET terminal_source='UNKNOWN' WHERE user_id=8101"));
          assertEquals("23514", invalid.getSQLState());
        }
      }
    } finally {
      dropTemporarySchema(schema);
    }
  }

  private static void migrate(String schema, String target) {
    Flyway.configure()
        .configuration(Map.of("flyway.postgresql.transactional.lock", "false"))
        .dataSource(dataSource())
        .locations("classpath:db/migration")
        .schemas(schema)
        .defaultSchema(schema)
        .baselineOnMigrate(true)
        .baselineVersion(PRIOR_VERSION)
        .target(target)
        .placeholderReplacement(false)
        .load()
        .migrate();
  }

  private static DataSource dataSource() {
    PGSimpleDataSource ds = new PGSimpleDataSource();
    ds.setUrl(System.getenv().getOrDefault("DB_URL", "jdbc:postgresql://localhost:5432/devpath"));
    ds.setUser(System.getenv().getOrDefault("DB_USER", "devpath"));
    ds.setPassword(System.getenv().getOrDefault("DB_PASSWORD", "localdev"));
    return ds;
  }

  private static String temporarySchemaName() {
    return "sandbox_et8_hardening_" + UUID.randomUUID().toString().replace("-", "");
  }

  private static void createPriorSchema(String schema) throws Exception {
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      st.execute("CREATE SCHEMA " + schema);
      st.execute("""
          CREATE TABLE %s.sandbox_sessions (
            id BIGSERIAL PRIMARY KEY,
            user_id BIGINT NOT NULL,
            content_id BIGINT,
            code_block_id BIGINT,
            language VARCHAR(16) NOT NULL,
            container_id VARCHAR(128),
            status VARCHAR(16) NOT NULL DEFAULT 'ALLOCATING',
            submitted_code TEXT NOT NULL,
            stdout TEXT,
            stderr TEXT,
            exit_code INT,
            cpu_ms_used BIGINT,
            memory_mb_peak INT,
            output_truncated BOOLEAN NOT NULL DEFAULT FALSE,
            started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
            finished_at TIMESTAMPTZ,
            created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
            updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
            CONSTRAINT chk_sandbox_language CHECK (language IN ('JAVA','NODE','PYTHON')),
            CONSTRAINT chk_sandbox_status CHECK (
              status IN ('ALLOCATING','RUNNING','COMPLETED','FAILED','KILLED','TIMED_OUT'))
          )
          """.formatted(schema));
      st.execute("""
          CREATE TABLE %s.outbox (
            id BIGSERIAL PRIMARY KEY,
            aggregate_type VARCHAR(100) NOT NULL,
            aggregate_id VARCHAR(100) NOT NULL,
            event_type VARCHAR(100) NOT NULL,
            payload JSONB NOT NULL,
            created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
            published_at TIMESTAMPTZ
          )
          """.formatted(schema));
      st.execute("INSERT INTO " + schema + ".sandbox_sessions"
          + "(user_id,language,status,submitted_code,started_at,updated_at) VALUES "
          + "(8001,'JAVA','ALLOCATING','old',now() - interval '2 minutes',"
          + "now() - interval '2 minutes'),"
          + "(8001,'JAVA','RUNNING','new',now() - interval '1 minute',"
          + "now() - interval '1 minute')");
    }
  }

  private static void dropTemporarySchema(String schema) throws Exception {
    if (!schema.matches("sandbox_et8_hardening_[a-f0-9]{32}")) {
      throw new IllegalArgumentException("refusing to drop unexpected schema: " + schema);
    }
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      st.execute("DROP SCHEMA IF EXISTS " + schema + " CASCADE");
    }
  }
}

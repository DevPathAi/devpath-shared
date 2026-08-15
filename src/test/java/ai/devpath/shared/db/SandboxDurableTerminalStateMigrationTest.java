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

/** ET8 Sandbox durable terminal-state additive migration contract. */
class SandboxDurableTerminalStateMigrationTest {

  private static final String PRIOR_VERSION = "202608151001";

  @Test
  void firstPhaseAddsAnUnvalidatedGuardWithoutDroppingTheLegacyConstraint()
      throws Exception {
    String schema = temporarySchemaName();

    try {
      createPriorSchemaWithExistingRows(schema);

      Flyway.configure()
          .dataSource(dataSource())
          .locations("classpath:db/migration")
          .schemas(schema)
          .defaultSchema(schema)
          .baselineOnMigrate(true)
          .baselineVersion(PRIOR_VERSION)
          .target("202608151002")
          .placeholderReplacement(false)
          .load()
          .migrate();

      try (var c = dataSource().getConnection();
          var constraint = c.prepareStatement(
              "SELECT conname,convalidated FROM pg_constraint "
                  + "WHERE conrelid = (? || '.sandbox_sessions')::regclass "
                  + "AND conname IN ('chk_sandbox_status','chk_sandbox_status_v2')")) {
        constraint.setString(1, schema);
        Map<String, Boolean> validation = new HashMap<>();
        try (var rs = constraint.executeQuery()) {
          while (rs.next()) validation.put(rs.getString(1), rs.getBoolean(2));
        }
        assertEquals(Boolean.TRUE, validation.get("chk_sandbox_status"));
        assertEquals(Boolean.FALSE, validation.get("chk_sandbox_status_v2"));
      }
    } finally {
      dropTemporarySchema(schema);
    }
  }

  @Test
  void upgradesPriorSandboxSchemaWithoutLosingRowsAndEnforcesTerminalContract()
      throws Exception {
    String schema = temporarySchemaName();
    assertTrue(schema.matches("sandbox_et8_[a-f0-9]{32}"));

    try {
      createPriorSchemaWithExistingRows(schema);

      Flyway.configure()
          .dataSource(dataSource())
          .locations("classpath:db/migration")
          .schemas(schema)
          .defaultSchema(schema)
          .baselineOnMigrate(true)
          .baselineVersion(PRIOR_VERSION)
          .placeholderReplacement(false)
          .load()
          .migrate();

      assertMigratedContract(schema);
    } finally {
      dropTemporarySchema(schema);
    }
  }

  private static DataSource dataSource() {
    PGSimpleDataSource ds = new PGSimpleDataSource();
    ds.setUrl(System.getenv().getOrDefault("DB_URL", "jdbc:postgresql://localhost:5432/devpath"));
    ds.setUser(System.getenv().getOrDefault("DB_USER", "devpath"));
    ds.setPassword(System.getenv().getOrDefault("DB_PASSWORD", "localdev"));
    return ds;
  }

  private static String temporarySchemaName() {
    return "sandbox_et8_" + UUID.randomUUID().toString().replace("-", "");
  }

  private static void createPriorSchemaWithExistingRows(String schema) throws Exception {
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      st.execute("CREATE SCHEMA " + schema);
      st.execute("""
          CREATE TABLE %s.sandbox_sessions (
            id              BIGSERIAL PRIMARY KEY,
            user_id         BIGINT NOT NULL,
            content_id      BIGINT,
            code_block_id   BIGINT,
            language        VARCHAR(16) NOT NULL,
            container_id    VARCHAR(128),
            status          VARCHAR(16) NOT NULL DEFAULT 'ALLOCATING',
            submitted_code  TEXT NOT NULL,
            stdout          TEXT,
            stderr          TEXT,
            exit_code       INT,
            cpu_ms_used     BIGINT,
            memory_mb_peak  INT,
            started_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
            finished_at     TIMESTAMPTZ,
            created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
            updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
            CONSTRAINT chk_sandbox_language
              CHECK (language IN ('JAVA','NODE','PYTHON')),
            CONSTRAINT chk_sandbox_status
              CHECK (status IN ('ALLOCATING','RUNNING','COMPLETED','FAILED','KILLED'))
          )
          """.formatted(schema));
      String[] existingStatuses = {"ALLOCATING", "RUNNING", "COMPLETED", "FAILED", "KILLED"};
      for (int i = 0; i < existingStatuses.length; i++) {
        st.execute("INSERT INTO " + schema + ".sandbox_sessions"
            + "(user_id,language,status,submitted_code,stdout,exit_code) "
            + "VALUES (" + (71001 + i) + ",'JAVA','" + existingStatuses[i]
            + "','class Main {}','existing " + existingStatuses[i] + "',0)");
      }
    }
  }

  private static void assertMigratedContract(String schema) throws Exception {
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      try (var column = c.prepareStatement(
          "SELECT data_type,is_nullable,column_default FROM information_schema.columns "
              + "WHERE table_schema = ? AND table_name = 'sandbox_sessions' "
              + "AND column_name = 'output_truncated'")) {
        column.setString(1, schema);
        try (var rs = column.executeQuery()) {
          assertTrue(rs.next(), "output_truncated column must exist after the migration");
          assertEquals("boolean", rs.getString("data_type"));
          assertEquals("NO", rs.getString("is_nullable"));
          assertEquals("false", rs.getString("column_default"));
          assertFalse(rs.next());
        }
      }

      try (var rs = st.executeQuery(
          "SELECT status,submitted_code,output_truncated FROM "
              + schema + ".sandbox_sessions WHERE user_id BETWEEN 71001 AND 71005 "
              + "ORDER BY user_id")) {
        String[] expectedStatuses = {"ALLOCATING", "RUNNING", "COMPLETED", "FAILED", "KILLED"};
        int index = 0;
        while (rs.next()) {
          assertEquals(expectedStatuses[index++], rs.getString("status"));
          assertEquals("class Main {}", rs.getString("submitted_code"));
          assertFalse(rs.getBoolean("output_truncated"),
              "existing rows must backfill output_truncated=false");
        }
        assertEquals(expectedStatuses.length, index,
            "all legacy execution statuses must survive the migration");
      }

      try (var constraint = c.prepareStatement(
          "SELECT convalidated,pg_get_constraintdef(oid) AS definition "
              + "FROM pg_constraint WHERE conrelid = (? || '.sandbox_sessions')::regclass "
              + "AND conname = 'chk_sandbox_status'")) {
        constraint.setString(1, schema);
        try (var rs = constraint.executeQuery()) {
          assertTrue(rs.next(), "final sandbox status constraint must exist");
          assertTrue(rs.getBoolean("convalidated"),
              "final sandbox status constraint must be fully validated");
          assertTrue(rs.getString("definition").contains("TIMED_OUT"));
          assertFalse(rs.next());
        }
      }
      try (var stale = c.prepareStatement(
          "SELECT 1 FROM pg_constraint "
              + "WHERE conrelid = (? || '.sandbox_sessions')::regclass "
              + "AND conname = 'chk_sandbox_status_v2'")) {
        stale.setString(1, schema);
        try (var rs = stale.executeQuery()) {
          assertFalse(rs.next(), "temporary v2 constraint name must be retired");
        }
      }

      try (var rs = st.executeQuery(
          "INSERT INTO " + schema + ".sandbox_sessions"
              + "(user_id,language,status,submitted_code) "
              + "VALUES (71002,'PYTHON','TIMED_OUT','print(1)') "
              + "RETURNING output_truncated")) {
        assertTrue(rs.next(), "TIMED_OUT must be accepted after the migration");
        assertFalse(rs.getBoolean("output_truncated"),
            "new rows that omit output_truncated must default to false");
      }

      SQLException bogus = assertThrows(SQLException.class, () ->
          st.execute("INSERT INTO " + schema + ".sandbox_sessions"
              + "(user_id,language,status,submitted_code) "
              + "VALUES (71003,'NODE','BOGUS','console.log(1)')"));
      assertEquals("23514", bogus.getSQLState(), "unknown status must remain rejected");
    }
  }

  private static void dropTemporarySchema(String schema) throws Exception {
    if (!schema.matches("sandbox_et8_[a-f0-9]{32}")) {
      throw new IllegalArgumentException("refusing to drop unexpected schema: " + schema);
    }
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      st.execute("DROP SCHEMA IF EXISTS " + schema + " CASCADE");
    }
  }
}

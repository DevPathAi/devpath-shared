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

/** ET9 LCS purpose/private/idempotency and immutable snapshot database contract. */
class LcsMentorSnapshotMigrationTest {

  private static final String PRIOR_VERSION = "202608161008";
  private static final String PHASE_ONE_VERSION = "202608161009";

  @Test
  void phaseOneEnforcesNewWritesBeforeValidatingExistingRows() throws Exception {
    String schema = temporarySchemaName();
    try {
      createPriorSchema(schema);
      migrateBaselined(schema, PHASE_ONE_VERSION);

      try (var c = dataSource().getConnection(); var st = c.createStatement()) {
        Map<String, Boolean> constraints = constraints(c, schema);
        assertFalse(constraints.containsKey("chk_lcs_purpose"),
            "the legacy purpose guard must no longer reject mentor_prompt");
        assertEquals(Boolean.FALSE, constraints.get("chk_lcs_purpose_v2"));
        assertEquals(Boolean.FALSE, constraints.get("chk_lcs_mentor_private"));
        assertEquals(Boolean.FALSE, constraints.get("chk_lcs_source_draft_id"));

        try (var rs = st.executeQuery(
            "SELECT data_type,character_maximum_length,is_nullable "
                + "FROM information_schema.columns WHERE table_schema='" + schema
                + "' AND table_name='learning_context_snapshots' "
                + "AND column_name='source_draft_id'")) {
          assertTrue(rs.next());
          assertEquals("character varying", rs.getString("data_type"));
          assertEquals(41, rs.getInt("character_maximum_length"));
          assertEquals("YES", rs.getString("is_nullable"));
        }

        // Mixed-version compatibility: the old Community writer omits source_draft_id.
        st.execute("INSERT INTO " + schema + ".learning_context_snapshots"
            + "(user_id,purpose,attached_to_type,attached_to_id,content_snapshot,visibility) "
            + "VALUES(42,'question_attachment','question',8,'{}','answerers_only')");

        assertCheckViolation(st, "INSERT INTO " + schema + ".learning_context_snapshots"
            + "(user_id,purpose,content_snapshot,visibility,source_draft_id) VALUES"
            + "(42,'mentor_prompt','{}','public','" + draftId('a') + "')");
        assertCheckViolation(st, "INSERT INTO " + schema + ".learning_context_snapshots"
            + "(user_id,purpose,attached_to_type,attached_to_id,content_snapshot,visibility,"
            + "source_draft_id) VALUES(42,'mentor_prompt','question',8,'{}','private','"
            + draftId('b') + "')");
        assertCheckViolation(st, "INSERT INTO " + schema + ".learning_context_snapshots"
            + "(user_id,purpose,content_snapshot,visibility) "
            + "VALUES(42,'mentor_prompt','{}','private')");
        assertCheckViolation(st, "INSERT INTO " + schema + ".learning_context_snapshots"
            + "(user_id,purpose,content_snapshot,visibility,source_draft_id) VALUES"
            + "(42,'mentor_prompt','{}','private','" + draftId('c').toUpperCase() + "')");
        assertCheckViolation(st, "INSERT INTO " + schema + ".learning_context_snapshots"
            + "(user_id,purpose,content_snapshot,visibility,source_draft_id) "
            + "VALUES(42,'mentor_prompt','{}','private','snap_not-a-uuid')");
        assertCheckViolation(st, "INSERT INTO " + schema + ".learning_context_snapshots"
            + "(user_id,purpose,attached_to_type,attached_to_id,content_snapshot,visibility,"
            + "source_draft_id) VALUES(42,'question_attachment','question',10,'{}',"
            + "'private','" + draftId('f') + "')");

        st.execute("INSERT INTO " + schema + ".learning_context_snapshots"
            + "(user_id,purpose,content_snapshot,visibility,source_draft_id) VALUES"
            + "(42,'mentor_prompt','{}','private','" + draftId('d') + "')");
      }
    } finally {
      dropSchema(schema);
    }
  }

  @Test
  void historicSchemaUpgradesWithUniqueCanonicalImmutableMentorSnapshots() throws Exception {
    String schema = temporarySchemaName();
    String sourceDraftId = draftId('e');
    long mentorId;
    try {
      createPriorSchema(schema);
      migrateBaselined(schema, null);

      try (var c = dataSource().getConnection(); var st = c.createStatement()) {
        Map<String, Boolean> constraints = constraints(c, schema);
        assertEquals(Boolean.TRUE, constraints.get("chk_lcs_purpose"));
        assertEquals(Boolean.TRUE, constraints.get("chk_lcs_mentor_private"));
        assertEquals(Boolean.TRUE, constraints.get("chk_lcs_source_draft_id"));
        assertFalse(constraints.containsKey("chk_lcs_purpose_v2"));

        try (var rs = st.executeQuery("SELECT count(*) FROM " + schema
            + ".learning_context_snapshots WHERE purpose='question_attachment'")) {
          assertTrue(rs.next());
          assertEquals(1, rs.getInt(1), "legacy Community rows must survive the upgrade");
        }

        // Old writer/new schema remains additive and source_draft_id stays nullable for Community.
        st.execute("INSERT INTO " + schema + ".learning_context_snapshots"
            + "(user_id,purpose,attached_to_type,attached_to_id,content_snapshot,visibility) "
            + "VALUES(43,'question_attachment','question',9,'{}','public')");

        try (var rs = st.executeQuery("INSERT INTO " + schema
            + ".learning_context_snapshots(user_id,purpose,content_snapshot,visibility,"
            + "fields_included,source_draft_id) VALUES"
            + "(42,'mentor_prompt','{\"current_content\":{\"contentId\":10}}','private',"
            + "'[\"current_content\"]','" + sourceDraftId + "') RETURNING id")) {
          assertTrue(rs.next());
          mentorId = rs.getLong(1);
        }

        SQLException duplicate = assertThrows(SQLException.class, () -> st.execute(
            "INSERT INTO " + schema
                + ".learning_context_snapshots(user_id,purpose,content_snapshot,visibility,"
                + "source_draft_id) VALUES(42,'mentor_prompt','{}','private','"
                + sourceDraftId + "')"));
        assertEquals("23505", duplicate.getSQLState(),
            "one source draft must commit to exactly one snapshot");

        for (String update : new String[] {
            "user_id=99", "purpose='question_attachment'", "content_snapshot='{}'",
            "visibility='public'", "fields_included='[]'", "source_draft_id='" + draftId('f') + "'",
            "attached_to_type='question',attached_to_id=1",
            "created_at=created_at + interval '1 second'"}) {
          SQLException immutable = assertThrows(SQLException.class, () -> st.execute(
              "UPDATE " + schema + ".learning_context_snapshots SET " + update
                  + " WHERE id=" + mentorId));
          assertEquals("23514", immutable.getSQLState(),
              "committed snapshot mutation must fail: " + update);
        }

        assertEquals(1, st.executeUpdate("DELETE FROM " + schema
            + ".learning_context_snapshots WHERE id=" + mentorId),
            "immutability must not block account-deletion cleanup");

        try (var rs = st.executeQuery("SELECT 1 FROM pg_indexes WHERE schemaname='" + schema
            + "' AND indexname='uq_lcs_source_draft_id'")) {
          assertTrue(rs.next(), "source draft replay requires a durable unique index");
        }
      }
    } finally {
      dropSchema(schema);
    }
  }

  private static void createPriorSchema(String schema) throws Exception {
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      st.execute("CREATE SCHEMA " + schema);
      st.execute("CREATE TABLE " + schema + ".learning_context_snapshots ("
          + "id BIGSERIAL PRIMARY KEY,user_id BIGINT NOT NULL,"
          + "purpose VARCHAR(32) NOT NULL DEFAULT 'question_attachment',"
          + "attached_to_type VARCHAR(32),attached_to_id BIGINT,"
          + "content_snapshot JSONB NOT NULL,"
          + "visibility VARCHAR(16) NOT NULL DEFAULT 'answerers_only',"
          + "fields_included JSONB NOT NULL DEFAULT '[]',"
          + "created_at TIMESTAMPTZ NOT NULL DEFAULT now(),"
          + "CONSTRAINT chk_lcs_purpose CHECK "
          + "(purpose IN ('question_attachment','analytics')),"
          + "CONSTRAINT chk_lcs_visibility CHECK "
          + "(visibility IN ('public','answerers_only','private')),"
          + "CONSTRAINT chk_lcs_attached_type CHECK "
          + "(attached_to_type IS NULL OR attached_to_type IN ('question','answer')))" );
      st.execute("INSERT INTO " + schema + ".learning_context_snapshots"
          + "(user_id,purpose,attached_to_type,attached_to_id,content_snapshot,visibility) "
          + "VALUES(42,'question_attachment','question',7,'{\"legacy\":true}',"
          + "'answerers_only')");
    }
  }

  private static void migrateBaselined(String schema, String target) {
    var config = Flyway.configure()
        .configuration(Map.of("flyway.postgresql.transactional.lock", "false"))
        .dataSource(dataSource())
        .locations("classpath:db/migration")
        .schemas(schema)
        .defaultSchema(schema)
        .baselineOnMigrate(true)
        .baselineVersion(PRIOR_VERSION)
        .placeholderReplacement(false);
    if (target != null) {
      config.target(target);
    }
    config.load().migrate();
  }

  private static Map<String, Boolean> constraints(java.sql.Connection c, String schema)
      throws Exception {
    try (var ps = c.prepareStatement(
        "SELECT conname,convalidated FROM pg_constraint "
            + "WHERE conrelid=(? || '.learning_context_snapshots')::regclass")) {
      ps.setString(1, schema);
      Map<String, Boolean> result = new HashMap<>();
      try (var rs = ps.executeQuery()) {
        while (rs.next()) {
          result.put(rs.getString(1), rs.getBoolean(2));
        }
      }
      return result;
    }
  }

  private static void assertCheckViolation(java.sql.Statement st, String sql) {
    SQLException violation = assertThrows(SQLException.class, () -> st.execute(sql));
    assertEquals("23514", violation.getSQLState());
  }

  private static String draftId(char repeated) {
    return "snap_" + String.valueOf(repeated).repeat(8) + "-" + String.valueOf(repeated).repeat(4)
        + "-4" + String.valueOf(repeated).repeat(3) + "-8"
        + String.valueOf(repeated).repeat(3) + "-" + String.valueOf(repeated).repeat(12);
  }

  private static String temporarySchemaName() {
    return "lcs_et9_" + UUID.randomUUID().toString().replace("-", "");
  }

  private static void dropSchema(String schema) throws Exception {
    if (!schema.matches("lcs_et9_[a-f0-9]{32}")) {
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

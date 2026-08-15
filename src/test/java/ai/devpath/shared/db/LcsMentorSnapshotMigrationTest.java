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
import org.flywaydb.core.api.FlywayException;
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

  @Test
  void unrelatedPartialSchemaMigratesLatestWithoutCreatingLcsObjects() throws Exception {
    String schema = temporarySchemaName();
    try {
      try (var c = dataSource().getConnection(); var st = c.createStatement()) {
        st.execute("CREATE SCHEMA " + schema);
        st.execute("CREATE TABLE " + schema + ".unrelated(id BIGINT PRIMARY KEY)");
      }

      configuredFlyway(schema, null).migrate();

      try (var c = dataSource().getConnection(); var ps = c.prepareStatement(
          "SELECT to_regclass(?), to_regclass(?)")) {
        ps.setString(1, schema + ".learning_context_snapshots");
        ps.setString(2, schema + ".uq_lcs_source_draft_id");
        try (var rs = ps.executeQuery()) {
          assertTrue(rs.next());
          assertEquals(null, rs.getObject(1));
          assertEquals(null, rs.getObject(2));
        }
      }
    } finally {
      dropSchema(schema);
    }
  }

  @Test
  void failedConcurrentUniqueBuildRepairsAndRetriesAfterDuplicateCleanup() throws Exception {
    String schema = temporarySchemaName();
    String duplicateDraftId = draftId('9');
    try {
      createPriorSchema(schema);
      migrateBaselined(schema, PHASE_ONE_VERSION);
      try (var c = dataSource().getConnection(); var st = c.createStatement()) {
        for (int i = 0; i < 2; i++) {
          st.execute("INSERT INTO " + schema + ".learning_context_snapshots"
              + "(user_id,purpose,content_snapshot,visibility,source_draft_id) VALUES"
              + "(42,'mentor_prompt','{}','private','" + duplicateDraftId + "')");
        }
      }

      Flyway firstAttempt = configuredFlyway(schema, "202608161010");
      assertThrows(FlywayException.class, firstAttempt::migrate);
      IndexState failed = indexState(schema);
      assertFalse(failed.valid());
      assertFalse(failed.ready());

      try (var c = dataSource().getConnection(); var st = c.createStatement()) {
        st.execute("DELETE FROM " + schema + ".learning_context_snapshots WHERE id = ("
            + "SELECT max(id) FROM " + schema
            + ".learning_context_snapshots WHERE source_draft_id='" + duplicateDraftId + "')");
      }
      firstAttempt.repair();
      configuredFlyway(schema, null).migrate();

      IndexState repaired = indexState(schema);
      assertTrue(repaired.valid());
      assertTrue(repaired.ready());
      assertTrue(repaired.unique());
      assertTrue(repaired.definition().contains("(source_draft_id)"));
    } finally {
      dropSchema(schema);
    }
  }

  @Test
  void successfulIndexWithLostHistoryReplaysAsNoOpAndPreservesOid() throws Exception {
    String schema = temporarySchemaName();
    try {
      createPriorSchema(schema);
      migrateBaselined(schema, "202608161010");
      IndexState before = indexState(schema);
      assertTrue(before.valid());
      assertTrue(before.ready());

      try (var c = dataSource().getConnection(); var st = c.createStatement()) {
        assertEquals(1, st.executeUpdate("DELETE FROM " + schema
            + ".flyway_schema_history WHERE version='202608161010'"));
      }

      configuredFlyway(schema, "202608161010").migrate();

      IndexState after = indexState(schema);
      assertEquals(before.oid(), after.oid(),
          "history-loss replay must not drop and rebuild an already exact valid index");
      assertTrue(after.valid());
      assertTrue(after.ready());
      assertTrue(after.unique());
    } finally {
      dropSchema(schema);
    }
  }

  @Test
  void sameNamedIndexOnTheWrongTableIsReplacedWithTheExactLcsDefinition()
      throws Exception {
    String schema = temporarySchemaName();
    try {
      createPriorSchema(schema);
      migrateBaselined(schema, PHASE_ONE_VERSION);
      try (var c = dataSource().getConnection(); var st = c.createStatement()) {
        st.execute("CREATE TABLE " + schema
            + ".wrong_index_owner(source_draft_id VARCHAR(41) NOT NULL UNIQUE)");
        st.execute("CREATE UNIQUE INDEX uq_lcs_source_draft_id ON " + schema
            + ".wrong_index_owner(source_draft_id)");
      }

      configuredFlyway(schema, null).migrate();

      try (var c = dataSource().getConnection(); var ps = c.prepareStatement("""
          SELECT table_class.relname
          FROM pg_index index_state
          JOIN pg_class index_class ON index_class.oid=index_state.indexrelid
          JOIN pg_namespace index_schema ON index_schema.oid=index_class.relnamespace
          JOIN pg_class table_class ON table_class.oid=index_state.indrelid
          WHERE index_schema.nspname=? AND index_class.relname='uq_lcs_source_draft_id'
          """)) {
        ps.setString(1, schema);
        try (var rs = ps.executeQuery()) {
          assertTrue(rs.next());
          assertEquals("learning_context_snapshots", rs.getString(1));
          assertFalse(rs.next());
        }
      }
    } finally {
      dropSchema(schema);
    }
  }

  @Test
  void sameNamedIndexWithNonDefaultDefinitionIsReplaced() throws Exception {
    String schema = temporarySchemaName();
    try {
      createPriorSchema(schema);
      migrateBaselined(schema, PHASE_ONE_VERSION);
      long mismatchedOid;
      try (var c = dataSource().getConnection(); var st = c.createStatement()) {
        st.execute("CREATE UNIQUE INDEX uq_lcs_source_draft_id ON " + schema
            + ".learning_context_snapshots(source_draft_id) NULLS NOT DISTINCT "
            + "WITH (fillfactor=80)");
        mismatchedOid = indexState(schema).oid();
      }

      configuredFlyway(schema, null).migrate();

      IndexState exact = indexState(schema);
      assertFalse(exact.oid() == mismatchedOid,
          "a non-default same-name definition must be rebuilt, not accepted as exact");
      try (var c = dataSource().getConnection(); var ps = c.prepareStatement("""
          SELECT index_state.indnullsnotdistinct,index_class.reloptions,
                 index_class.reltablespace
          FROM pg_index index_state
          JOIN pg_class index_class ON index_class.oid=index_state.indexrelid
          JOIN pg_namespace index_schema ON index_schema.oid=index_class.relnamespace
          WHERE index_schema.nspname=? AND index_class.relname='uq_lcs_source_draft_id'
          """)) {
        ps.setString(1, schema);
        try (var rs = ps.executeQuery()) {
          assertTrue(rs.next());
          assertFalse(rs.getBoolean(1));
          assertEquals(null, rs.getArray(2));
          assertEquals(0, rs.getLong(3));
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
    configuredFlyway(schema, target).migrate();
  }

  private static Flyway configuredFlyway(String schema, String target) {
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
    return config.load();
  }

  private static IndexState indexState(String schema) throws Exception {
    try (var c = dataSource().getConnection(); var ps = c.prepareStatement("""
        SELECT cls.oid,idx.indisvalid,idx.indisready,idx.indisunique,
               pg_get_indexdef(idx.indexrelid)
        FROM pg_index idx
        JOIN pg_class cls ON cls.oid=idx.indexrelid
        JOIN pg_namespace ns ON ns.oid=cls.relnamespace
        WHERE ns.nspname=? AND cls.relname='uq_lcs_source_draft_id'
        """)) {
      ps.setString(1, schema);
      try (var rs = ps.executeQuery()) {
        assertTrue(rs.next(), "source draft index must exist");
        IndexState state = new IndexState(
            rs.getLong(1), rs.getBoolean(2), rs.getBoolean(3), rs.getBoolean(4), rs.getString(5));
        assertFalse(rs.next());
        return state;
      }
    }
  }

  private record IndexState(
      long oid, boolean valid, boolean ready, boolean unique, String definition) {
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

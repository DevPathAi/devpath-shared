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

/** Upgrade contract for databases that already recorded the original guest-claim migration. */
class AssessmentGuestClaimUpgradeMigrationTest {

  private static final String ORIGINAL_VERSION = "202608151001";
  private static final int ORIGINAL_CHECKSUM = -1397021464;

  @Test
  void originalChecksumValidatesAndUpgradesToCanonicalImmutableGuestIds() throws Exception {
    String schema = temporarySchemaName();
    try {
      Flyway original = flyway(schema, ORIGINAL_VERSION);
      original.migrate();

      var originalValidation = original.validateWithResult();
      assertTrue(originalValidation.validationSuccessful,
          originalValidation.getAllErrorMessages());
      assertEquals(ORIGINAL_CHECKSUM, appliedChecksum(schema, ORIGINAL_VERSION),
          "already-applied V202608151001 bytes must remain immutable");

      long assessmentId;
      try (var c = dataSource().getConnection(); var ps = c.prepareStatement(
          "INSERT INTO " + schema + ".assessments(source_guest_id,track) "
              + "VALUES ('AAAAAAAA-AAAA-4AAA-8AAA-AAAAAAAAAAAA','BACKEND_SPRING') "
              + "RETURNING id")) {
        try (var rs = ps.executeQuery()) {
          assertTrue(rs.next());
          assessmentId = rs.getLong(1);
        }
      }

      Flyway latest = flyway(schema, null);
      latest.migrate();

      var latestValidation = latest.validateWithResult();
      assertTrue(latestValidation.validationSuccessful,
          latestValidation.getAllErrorMessages());
      assertEquals(ORIGINAL_CHECKSUM, appliedChecksum(schema, ORIGINAL_VERSION));

      try (var c = dataSource().getConnection(); var st = c.createStatement()) {
        try (var rs = st.executeQuery("SELECT source_guest_id FROM " + schema
            + ".assessments WHERE id=" + assessmentId)) {
          assertTrue(rs.next());
          assertEquals("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa", rs.getString(1),
              "pre-hardening uppercase IDs must be normalized during the upgrade");
        }

        SQLException uppercaseInsert = assertThrows(SQLException.class, () -> st.execute(
            "INSERT INTO " + schema + ".assessments(source_guest_id,track) VALUES "
                + "('BBBBBBBB-BBBB-4BBB-8BBB-BBBBBBBBBBBB','BACKEND_SPRING')"));
        assertEquals("23514", uppercaseInsert.getSQLState());

        SQLException reassignment = assertThrows(SQLException.class, () -> st.execute(
            "UPDATE " + schema + ".assessments SET source_guest_id="
                + "'cccccccc-cccc-4ccc-8ccc-cccccccccccc' WHERE id=" + assessmentId));
        assertEquals("23514", reassignment.getSQLState());

        try (var rs = st.executeQuery(
            "SELECT convalidated FROM pg_constraint WHERE conrelid='" + schema
                + ".assessments'::regclass AND conname="
                + "'chk_assessments_source_guest_id_uuid'")) {
          assertTrue(rs.next());
          assertTrue(rs.getBoolean(1), "canonical guest-id constraint must be validated");
        }
      }
    } finally {
      dropSchema(schema);
    }
  }

  @Test
  void caseInsensitiveGuestIdCollisionStopsTheUpgradeWithoutMergingRows() throws Exception {
    String schema = temporarySchemaName();
    String lowercase = "dddddddd-dddd-4ddd-8ddd-dddddddddddd";
    String uppercase = lowercase.toUpperCase(java.util.Locale.ROOT);
    try {
      flyway(schema, ORIGINAL_VERSION).migrate();
      try (var c = dataSource().getConnection(); var ps = c.prepareStatement(
          "INSERT INTO " + schema + ".assessments(source_guest_id,track) "
              + "VALUES (?,'BACKEND_SPRING')")) {
        ps.setString(1, lowercase);
        assertEquals(1, ps.executeUpdate());
        ps.setString(1, uppercase);
        assertEquals(1, ps.executeUpdate(),
            "the historical contract allowed a case-variant semantic collision");
      }

      FlywayException failure = assertThrows(FlywayException.class,
          () -> flyway(schema, null).migrate());
      assertTrue(failure.getMessage().contains(
          "case-insensitive duplicate assessments.source_guest_id values require remediation"),
          "the migration must explain the fail-closed remediation gate");

      try (var c = dataSource().getConnection(); var st = c.createStatement()) {
        try (var rs = st.executeQuery("SELECT count(*) FROM " + schema
            + ".assessments WHERE lower(source_guest_id)='" + lowercase + "'")) {
          assertTrue(rs.next());
          assertEquals(2, rs.getInt(1), "a failed upgrade must not auto-merge assessments");
        }
        try (var rs = st.executeQuery("SELECT count(*) FROM " + schema
            + ".flyway_schema_history WHERE version='202608161005'")) {
          assertTrue(rs.next());
          assertEquals(0, rs.getInt(1), "the failed transactional migration must not be recorded");
        }
      }
    } finally {
      dropSchema(schema);
    }
  }

  private static Flyway flyway(String schema, String target) {
    var config = Flyway.configure()
        .configuration(Map.of("flyway.postgresql.transactional.lock", "false"))
        .dataSource(dataSource())
        .locations("classpath:db/migration")
        .schemas(schema)
        .defaultSchema(schema)
        .placeholderReplacement(false);
    if (target != null) config.target(target);
    return config.load();
  }

  private static int appliedChecksum(String schema, String version) throws Exception {
    try (var c = dataSource().getConnection(); var ps = c.prepareStatement(
        "SELECT checksum FROM " + schema + ".flyway_schema_history WHERE version=?")) {
      ps.setString(1, version);
      try (var rs = ps.executeQuery()) {
        assertTrue(rs.next(), "migration history row must exist for " + version);
        return rs.getInt(1);
      }
    }
  }

  private static String temporarySchemaName() {
    return "guest_claim_upgrade_" + UUID.randomUUID().toString().replace("-", "");
  }

  private static void dropSchema(String schema) throws Exception {
    if (!schema.matches("guest_claim_upgrade_[a-f0-9]{32}")) {
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

package ai.devpath.shared.db;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;

/** Keeps the deployment image and recovery documentation aligned with the JDBC migration. */
class MigrationRunnerPackagingTest {

  private static final Path ROOT = Path.of("").toAbsolutePath();

  @Test
  void unpublishedV1010IsOnlyThePackagedJavaMigration() throws Exception {
    assertTrue(Files.isRegularFile(ROOT.resolve(
        "src/main/java/db/migration/V202608161010__lcs_source_draft_unique_index.java")));
    assertFalse(Files.exists(ROOT.resolve(
        "src/main/resources/db/migration/V202608161010__lcs_source_draft_unique_index.sql")));
    assertFalse(Files.exists(ROOT.resolve(
        "src/main/resources/db/migration/V202608161010__lcs_source_draft_unique_index.sql.conf")));

    String build = Files.readString(ROOT.resolve("build.gradle.kts"));
    assertTrue(build.contains("tasks.register<Jar>(\"migrationRunnerJar\")"));
    assertTrue(build.contains("include(\"db/migration/**\")"));

    String dockerfile = Files.readString(ROOT.resolve("Dockerfile.migration"));
    assertTrue(dockerfile.contains("/workspace/build/libs/*-migration-runner.jar /flyway/drivers/"));
    assertTrue(dockerfile.contains(
        "FLYWAY_LOCATIONS=filesystem:/flyway/sql,classpath:db/migration"));
  }

  @Test
  void retryAndLowLockRunbookNamesTheExactOperationalSequence() throws Exception {
    String runbook = Files.readString(ROOT.resolve(
        "docs/lcs-source-draft-index-migration-runbook.md"));
    assertTrue(runbook.contains("V202608161010"));
    assertTrue(runbook.contains("indisvalid"));
    assertTrue(runbook.contains("flyway repair"));
    assertTrue(runbook.contains("flyway migrate"));
    assertTrue(runbook.indexOf("flyway repair") < runbook.lastIndexOf("flyway migrate"));
    assertTrue(runbook.contains("CREATE UNIQUE INDEX CONCURRENTLY"));
    assertTrue(runbook.contains("source_draft_id IS NOT NULL"));
  }
}

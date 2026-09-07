package ai.devpath.shared;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;

class ReleaseCoordinateContractTest {

  @Test
  void mentorAccessUsesOneUniqueImmutableMavenVersion() throws Exception {
    String build = Files.readString(Path.of("build.gradle.kts"));

    assertTrue(build.contains("version = \"0.0.1-rm.20260907\""));
    assertFalse(build.contains("version = \"0.0.1-SNAPSHOT\""));
    assertFalse(build.contains("version = \"0.0.1-et9.20260816\""));
    assertFalse(build.contains("version = \"0.0.1-et10.20260820\""));
    assertFalse(build.contains("version = \"0.0.1-et11.20260822\""));
    assertFalse(build.contains("version = \"0.0.1-rh.20260905\""));
    assertTrue(build.contains("immutableSharedRepository"));
  }
}

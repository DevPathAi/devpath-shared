package ai.devpath.shared.event;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class AssessmentCompletedEventTest {

  @Test
  void eventTypeIsStable() {
    var event = new AssessmentCompletedEvent(
        UUID.randomUUID(), Instant.now(), 10L, 1L, "BACKEND_SPRING", "MID",
        Map.of("jpa", 0.8, "spring-security", 0.4), Instant.now());
    assertEquals("learning.assessment.completed", event.eventType());
  }

  @Test
  void conceptScoresMayBeNull() {
    var event = new AssessmentCompletedEvent(
        UUID.randomUUID(), Instant.now(), 10L, 1L, "BACKEND_SPRING", "JUNIOR", null, Instant.now());
    assertNull(event.conceptScores());
    assertEquals("learning.assessment.completed", event.eventType());
  }
}

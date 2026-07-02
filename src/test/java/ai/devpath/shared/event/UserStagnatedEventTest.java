package ai.devpath.shared.event;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class UserStagnatedEventTest {

  @Test
  void eventTypeAndFields() {
    Instant now = Instant.now();
    Instant lastActive = now.minusSeconds(3 * 86400);
    UserStagnatedEvent e = new UserStagnatedEvent(UUID.randomUUID(), now, 42L, lastActive, 3, "백엔드 스프링 트랙 (12주 과정)");

    assertEquals("progress.user.stagnated", e.eventType());
    assertEquals("progress.user.stagnated", UserStagnatedEvent.EVENT_TYPE);
    assertEquals(42L, e.userId());
    assertEquals(3, e.daysInactive());
    assertEquals(lastActive, e.lastActiveAt());
    assertEquals("백엔드 스프링 트랙 (12주 과정)", e.currentLearningPathSummary());
  }

  @Test
  void summaryMayBeNull() {
    UserStagnatedEvent e = new UserStagnatedEvent(UUID.randomUUID(), Instant.now(), 1L, Instant.now(), 3, null);
    assertNull(e.currentLearningPathSummary());
  }
}

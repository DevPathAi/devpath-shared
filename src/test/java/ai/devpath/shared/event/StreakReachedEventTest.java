package ai.devpath.shared.event;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class StreakReachedEventTest {

  @Test
  void eventTypeMatchesConstant() {
    StreakReachedEvent event = new StreakReachedEvent(UUID.randomUUID(), Instant.now(), 42L, 30);

    assertEquals("progress.streak.reached", event.eventType());
    assertEquals("progress.streak.reached", StreakReachedEvent.EVENT_TYPE);
    assertEquals(42L, event.userId());
    assertEquals(30, event.days());
  }
}

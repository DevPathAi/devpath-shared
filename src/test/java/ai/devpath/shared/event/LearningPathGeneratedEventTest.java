package ai.devpath.shared.event;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class LearningPathGeneratedEventTest {

	@Test
	void eventTypeIsStable() {
		var event = new LearningPathGeneratedEvent(UUID.randomUUID(), Instant.now(), 1L, 10L, "backend");
		assertEquals("learning.path.generated", event.eventType());
	}
}

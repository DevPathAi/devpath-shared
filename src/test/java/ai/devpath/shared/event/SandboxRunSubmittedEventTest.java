package ai.devpath.shared.event;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class SandboxRunSubmittedEventTest {

	@Test
	void eventTypeIsStable() {
		var event = new SandboxRunSubmittedEvent(
				UUID.randomUUID(), Instant.now(), 1L, 10L, "PYTHON", 5L);
		assertEquals("sandbox.run.submitted", event.eventType());
	}

	@Test
	void contentIdIsNullable() {
		var event = new SandboxRunSubmittedEvent(
				UUID.randomUUID(), Instant.now(), 1L, 10L, "JAVA", null);
		assertEquals(null, event.contentId());
	}
}

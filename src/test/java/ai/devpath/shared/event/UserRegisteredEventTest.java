package ai.devpath.shared.event;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class UserRegisteredEventTest {

	@Test
	void eventTypeIsStable() {
		var event = new UserRegisteredEvent(UUID.randomUUID(), Instant.now(), 1L, "GITHUB", "u@example.com");
		assertEquals("user.user.registered", event.eventType());
	}

	@Test
	void emailMayBeNull() {
		var event = new UserRegisteredEvent(UUID.randomUUID(), Instant.now(), 1L, "GITHUB", null);
		assertEquals("user.user.registered", event.eventType());
	}
}

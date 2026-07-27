package ai.devpath.shared.event;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class BetaEventTest {

	@Test
	void waitlistEventTypeIsStable() {
		var event = new BetaWaitlistRegisteredEvent(UUID.randomUUID(), Instant.now(), 1L, "u@example.com");
		assertEquals("user.beta.waitlisted", event.eventType());
	}

	@Test
	void approvedEventTypeIsStable() {
		var event = new BetaAccessApprovedEvent(UUID.randomUUID(), Instant.now(), 1L, "u@example.com");
		assertEquals("user.beta.approved", event.eventType());
	}

	@Test
	void emailMayBeNull() {
		var w = new BetaWaitlistRegisteredEvent(UUID.randomUUID(), Instant.now(), 1L, null);
		var a = new BetaAccessApprovedEvent(UUID.randomUUID(), Instant.now(), 1L, null);
		assertEquals("user.beta.waitlisted", w.eventType());
		assertEquals("user.beta.approved", a.eventType());
	}
}

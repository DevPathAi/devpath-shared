package ai.devpath.shared.event;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class CommunitySeedReadyEventTest {

	@Test
	void eventTypeIsStable() {
		var event = new CommunitySeedReadyEvent(
				UUID.randomUUID(), Instant.now(), 10L, "DONE", "답변", "MOCK", List.of(0.1, 0.2), null);
		assertEquals("community.seed.ready", event.eventType());
	}

	@Test
	void failedSeedHasNullContentAndEmbedding() {
		var event = new CommunitySeedReadyEvent(
				UUID.randomUUID(), Instant.now(), 10L, "FAILED", null, "CLAUDE", null, "LLM_FAILED");
		assertEquals("FAILED", event.status());
		assertNull(event.content());
		assertNull(event.questionEmbedding());
		assertEquals("LLM_FAILED", event.errorCode());
	}
}

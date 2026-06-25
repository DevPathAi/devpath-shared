package ai.devpath.shared.event;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class CommunityQuestionPostedEventTest {

	@Test
	void eventTypeIsStable() {
		var event = new CommunityQuestionPostedEvent(
				UUID.randomUUID(), Instant.now(), 1L, 10L, 10L, "JPA N+1?", "본문...");
		assertEquals("community.question.posted", event.eventType());
	}

	@Test
	void carriesQuestionBodyForSeedWorker() {
		var event = new CommunityQuestionPostedEvent(
				UUID.randomUUID(), Instant.now(), 7L, 42L, 42L, "제목", "마크다운 본문");
		assertEquals(42L, event.questionId());
		assertEquals("제목", event.title());
		assertEquals("마크다운 본문", event.bodyMd());
	}
}

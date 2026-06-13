package ai.devpath.shared.event;

import java.time.Instant;
import java.util.UUID;

/**
 * 학습 경로 생성 완료 이벤트 (1st Aha).
 * learning-svc가 발행하고 notification 등이 구독한다.
 */
public record LearningPathGeneratedEvent(
		UUID eventId,
		Instant occurredAt,
		long userId,
		long learningPathId,
		String targetTrack
) implements DomainEvent {

	public static final String EVENT_TYPE = "learning.path.generated";

	@Override
	public String eventType() {
		return EVENT_TYPE;
	}
}

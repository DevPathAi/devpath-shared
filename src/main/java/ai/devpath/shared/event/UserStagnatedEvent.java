package ai.devpath.shared.event;

import java.time.Instant;
import java.util.UUID;

/**
 * 3일 연속 미활동(정체) 도달 이벤트. learning-svc가 Transactional Outbox로 에피소드당 1회 발행한다.
 * 소비자: notification-svc {@code StagnationConsumer}(→ ai-svc 재참여 문구 → 푸시).
 * {@code currentLearningPathSummary}는 발행 측(learning-svc)이 조립한 현재 활성 학습경로 요약(없으면 null).
 */
public record UserStagnatedEvent(
		UUID eventId,
		Instant occurredAt,
		long userId,
		Instant lastActiveAt,
		int daysInactive,
		String currentLearningPathSummary
) implements DomainEvent {

	public static final String EVENT_TYPE = "progress.user.stagnated";

	@Override
	public String eventType() {
		return EVENT_TYPE;
	}
}

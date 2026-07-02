package ai.devpath.shared.event;

import java.time.Instant;
import java.util.UUID;

/**
 * 스트릭 마일스톤(7/14/30/60/100일) 도달 이벤트.
 * learning-svc가 Transactional Outbox로 발행한다. 소비자: community-svc(days==30 → COMMUNITY 배지).
 */
public record StreakReachedEvent(
		UUID eventId,
		Instant occurredAt,
		long userId,
		int days
) implements DomainEvent {

	public static final String EVENT_TYPE = "progress.streak.reached";

	@Override
	public String eventType() {
		return EVENT_TYPE;
	}
}

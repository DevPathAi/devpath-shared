package ai.devpath.shared.event;

import java.time.Instant;
import java.util.UUID;

/**
 * 커뮤니티 배지 수여 이벤트.
 * community-svc가 Transactional Outbox로 발행한다. 소비자(notification-worker)는 후속.
 */
public record CommunityBadgeAwardedEvent(
		UUID eventId,
		Instant occurredAt,
		long userId,
		String badgeCode,
		long badgeId,
		String sourceType,
		long sourceId
) implements DomainEvent {

	public static final String EVENT_TYPE = "community.badge.awarded";

	@Override
	public String eventType() {
		return EVENT_TYPE;
	}
}

package ai.devpath.shared.event;

import java.time.Instant;
import java.util.UUID;

/**
 * 평판 조작(담합/sockpuppet) 의심 이벤트.
 * community-svc가 Transactional Outbox로 발행한다. 소비자(moderation)는 후속.
 */
public record CommunityReputationSuspectedEvent(
		UUID eventId,
		Instant occurredAt,
		long actorId,
		long targetUserId,
		String reason,
		int evidenceCount
) implements DomainEvent {

	public static final String EVENT_TYPE = "community.reputation.suspected";

	@Override
	public String eventType() {
		return EVENT_TYPE;
	}
}

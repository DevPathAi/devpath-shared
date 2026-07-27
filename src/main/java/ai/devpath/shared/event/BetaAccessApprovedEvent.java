package ai.devpath.shared.event;

import java.time.Instant;
import java.util.UUID;

/** 베타 승인된 사용자 이벤트. platform-svc 발행, notification 구독. */
public record BetaAccessApprovedEvent(
		UUID eventId,
		Instant occurredAt,
		long userId,
		String email
) implements DomainEvent {

	public static final String EVENT_TYPE = "user.beta.approved";

	@Override
	public String eventType() {
		return EVENT_TYPE;
	}
}

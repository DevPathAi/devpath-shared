package ai.devpath.shared.event;

import java.time.Instant;
import java.util.UUID;

/** 베타 미승인 사용자가 로그인해 대기명단에 오른 이벤트. platform-svc 발행, notification 구독. */
public record BetaWaitlistRegisteredEvent(
		UUID eventId,
		Instant occurredAt,
		long userId,
		String email
) implements DomainEvent {

	public static final String EVENT_TYPE = "user.beta.waitlisted";

	@Override
	public String eventType() {
		return EVENT_TYPE;
	}
}

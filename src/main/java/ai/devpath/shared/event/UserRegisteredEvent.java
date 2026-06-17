package ai.devpath.shared.event;

import java.time.Instant;
import java.util.UUID;

/**
 * 사용자 가입(최초 OAuth 연동) 완료 이벤트.
 * platform-svc가 발행하고 notification 등이 구독한다.
 * email은 provider가 미반환할 수 있어 nullable이다 (설계서 R4).
 */
public record UserRegisteredEvent(
		UUID eventId,
		Instant occurredAt,
		long userId,
		String provider,
		String email
) implements DomainEvent {

	public static final String EVENT_TYPE = "user.user.registered";

	@Override
	public String eventType() {
		return EVENT_TYPE;
	}
}

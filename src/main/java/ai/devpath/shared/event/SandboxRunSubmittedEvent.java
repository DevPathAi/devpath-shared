package ai.devpath.shared.event;

import java.time.Instant;
import java.util.UUID;

/**
 * 샌드박스 코드 실행 제출 이벤트.
 * sandbox-svc가 Transactional Outbox로 발행하고, ai-svc(코드 리뷰, 슬라이스 #6)가 구독한다.
 * contentId는 실습 콘텐츠 연결로 nullable이다.
 */
public record SandboxRunSubmittedEvent(
		UUID eventId,
		Instant occurredAt,
		long userId,
		long sandboxSessionId,
		String language,
		Long contentId
) implements DomainEvent {

	public static final String EVENT_TYPE = "sandbox.run.submitted";

	@Override
	public String eventType() {
		return EVENT_TYPE;
	}
}

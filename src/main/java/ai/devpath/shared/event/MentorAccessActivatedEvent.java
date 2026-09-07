package ai.devpath.shared.event;

import java.time.Instant;
import java.util.UUID;

/** 배치·초대 코드·관리자 승인으로 멘토 접근이 활성화된 이벤트. */
public record MentorAccessActivatedEvent(
    UUID eventId,
    Instant occurredAt,
    long userId,
    String email,
    String source,
    Instant activatedAt,
    Long batchId
) implements DomainEvent {
  @Override
  public String eventType() {
    return MentorEventTypes.ACCESS_ACTIVATED;
  }
}

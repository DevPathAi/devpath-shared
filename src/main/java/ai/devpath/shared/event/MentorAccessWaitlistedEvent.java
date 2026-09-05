package ai.devpath.shared.event;

import java.time.Instant;
import java.util.UUID;

/** 일반 로그인 사용자가 멘토 대기열에 등록된 이벤트. */
public record MentorAccessWaitlistedEvent(
    UUID eventId,
    Instant occurredAt,
    long userId,
    String email,
    Instant waitlistedAt
) implements DomainEvent {
  @Override
  public String eventType() {
    return MentorEventTypes.ACCESS_WAITLISTED;
  }
}

package ai.devpath.shared.event;

import java.time.Instant;
import java.util.UUID;

/** 실제 메일 전송 성공을 발송 수 집계에 반영하는 이벤트. */
public record MentorInviteEmailSentEvent(
    UUID eventId,
    Instant occurredAt,
    long userId,
    Long batchId,
    String deliveryId,
    Instant sentAt
) implements DomainEvent {
  @Override
  public String eventType() {
    return MentorEventTypes.INVITE_EMAIL_SENT;
  }
}

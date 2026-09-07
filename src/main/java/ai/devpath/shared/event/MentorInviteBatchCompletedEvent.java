package ai.devpath.shared.event;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/** 하루 초대 배치가 활성화와 outbox 기록을 끝낸 이벤트. */
public record MentorInviteBatchCompletedEvent(
    UUID eventId,
    Instant occurredAt,
    long batchId,
    LocalDate batchDate,
    int activatedCount
) implements DomainEvent {
  @Override
  public String eventType() {
    return MentorEventTypes.INVITE_BATCH_COMPLETED;
  }
}

package ai.devpath.shared.event;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * 주간 리포트 생성 이벤트. learning-svc가 매주(일 20:00 KST) 유저별로 Transactional Outbox로 발행한다.
 * 소비자: notification-svc {@code WeeklyReportConsumer}(→ weekly_report 저장 + 이메일 + 푸시).
 * {@code badgesEarnedThisWeek}는 이번주 획득 배지명 목록(없으면 빈 리스트), {@code nextTaskTitle}은 없으면 null.
 */
public record WeeklyReportGeneratedEvent(
		UUID eventId,
		Instant occurredAt,
		long userId,
		LocalDate weekOf,
		int streakDays,
		int progressPercent,
		List<String> badgesEarnedThisWeek,
		String nextTaskTitle
) implements DomainEvent {

	public static final String EVENT_TYPE = "progress.report.generated";

	@Override
	public String eventType() {
		return EVENT_TYPE;
	}
}

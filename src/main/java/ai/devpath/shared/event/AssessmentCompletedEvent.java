package ai.devpath.shared.event;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/**
 * 진단(온보딩 적응형 평가) 완료 이벤트.
 * learning-svc가 발행하고 platform-svc(온보딩 상태 전이)·learning-svc(경로 생성)가 구독한다.
 * conceptScores는 강·약점 집계로, 하위호환 위해 nullable이다.
 */
public record AssessmentCompletedEvent(
		UUID eventId,
		Instant occurredAt,
		long assessmentId,
		long userId,
		String track,
		String diagnosedLevel,
		Map<String, Double> conceptScores,
		Instant completedAt
) implements DomainEvent {

	public static final String EVENT_TYPE = "learning.assessment.completed";

	@Override
	public String eventType() {
		return EVENT_TYPE;
	}
}

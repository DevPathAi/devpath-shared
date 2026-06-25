package ai.devpath.shared.event;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * 커뮤니티 AI 시드 답변 준비 이벤트.
 * ai-svc가 질문을 받아 시드 답변(+질문 임베딩)을 생성한 뒤 Transactional Outbox로 발행하고,
 * community-svc가 구독해 community_answers/community_ai_answers/question_embedding을 영속한다(설계 D-1).
 * status=FAILED면 content/questionEmbedding은 null일 수 있고 errorCode가 채워진다.
 */
public record CommunitySeedReadyEvent(
		UUID eventId,
		Instant occurredAt,
		long questionId,
		String status,
		String content,
		String provider,
		List<Double> questionEmbedding,
		String errorCode
) implements DomainEvent {

	public static final String EVENT_TYPE = "community.seed.ready";

	@Override
	public String eventType() {
		return EVENT_TYPE;
	}
}

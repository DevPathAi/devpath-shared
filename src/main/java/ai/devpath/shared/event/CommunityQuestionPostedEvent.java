package ai.devpath.shared.event;

import java.time.Instant;
import java.util.UUID;

/**
 * 커뮤니티 Q&A 질문 게시 이벤트.
 * community-svc가 Transactional Outbox로 발행하고, ai-svc(AI 시드 답변, 슬라이스 #8)가 구독한다.
 * 질문 본문(title·bodyMd)을 동봉해 ai-svc가 역조회 없이 시드 답변을 생성한다(설계 D-2).
 */
public record CommunityQuestionPostedEvent(
		UUID eventId,
		Instant occurredAt,
		long userId,
		long questionId,
		long postId,
		String title,
		String bodyMd
) implements DomainEvent {

	public static final String EVENT_TYPE = "community.question.posted";

	@Override
	public String eventType() {
		return EVENT_TYPE;
	}
}

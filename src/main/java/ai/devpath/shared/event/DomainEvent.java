package ai.devpath.shared.event;

import java.time.Instant;
import java.util.UUID;

/**
 * 모든 도메인 이벤트의 공통 계약.
 * Transactional Outbox로 발행되는 이벤트는 이 인터페이스를 구현한다.
 */
public interface DomainEvent {

	UUID eventId();

	Instant occurredAt();

	/** Kafka 토픽 결정에 사용하는 이벤트 타입 식별자 (예: learning.path.generated) */
	String eventType();
}

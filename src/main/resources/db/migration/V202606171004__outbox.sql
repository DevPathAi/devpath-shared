-- Transactional Outbox: 도메인 트랜잭션과 동일 커밋으로 이벤트 기록 → 릴레이가 Kafka로 발행.
CREATE TABLE outbox (
  id             BIGSERIAL PRIMARY KEY,
  aggregate_type VARCHAR(100) NOT NULL,
  aggregate_id   VARCHAR(100) NOT NULL,
  event_type     VARCHAR(100) NOT NULL,
  payload        JSONB NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  published_at   TIMESTAMPTZ
);
CREATE INDEX idx_outbox_unpublished ON outbox(created_at) WHERE published_at IS NULL;

-- Sandbox 제출을 스트릭 활동 신호로 쓰기 위한 최소 로그. owner: devpath-learning-svc.
CREATE TABLE sandbox_activity_log (
  id          BIGSERIAL PRIMARY KEY,
  user_id     BIGINT NOT NULL,
  occurred_at TIMESTAMPTZ NOT NULL
);
CREATE INDEX idx_sandbox_activity_user_date ON sandbox_activity_log (user_id, occurred_at);

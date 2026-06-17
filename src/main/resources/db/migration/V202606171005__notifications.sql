-- 슬라이스 #1 D-8: 최소 알림 테이블(환영 알림 소비자 산출처). 04_API §9 알림 목록 기반.
CREATE TABLE notifications (
  id         BIGSERIAL PRIMARY KEY,
  user_id    BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type       VARCHAR(40) NOT NULL,
  title      VARCHAR(255) NOT NULL,
  body       TEXT,
  read_at    TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_notifications_user_created ON notifications(user_id, created_at);
-- P1-4: WELCOME 알림은 사용자당 1개(소비 레이스/중복 발행 시 DB가 멱등 보장).
CREATE UNIQUE INDEX uq_notifications_welcome_user ON notifications(user_id) WHERE type = 'WELCOME';

-- 하드닝 트랙 C: FCM 디바이스 토큰(사용자별, 타깃 푸시 발송용).
-- 모바일 로그인 후 getToken() 결과를 POST /notifications/devices로 등록한다.
CREATE TABLE device_tokens (
  id         BIGSERIAL PRIMARY KEY,
  user_id    BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token      VARCHAR(512) NOT NULL,
  platform   VARCHAR(16) NOT NULL,        -- ANDROID | IOS
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- 토큰은 전역 유일(기기 1대=토큰 1개). 재등록은 token 기준 upsert로 멱등 처리.
CREATE UNIQUE INDEX uq_device_tokens_token ON device_tokens(token);
CREATE INDEX idx_device_tokens_user ON device_tokens(user_id);

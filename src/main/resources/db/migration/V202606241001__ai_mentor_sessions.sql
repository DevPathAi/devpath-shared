-- MD3 Slice #7: AI mentor Q&A sessions (single-turn, one row per question-answer).
-- user_id(platform) / content_id(learning) are cross-service logical references only
-- - NO FK (service boundary; slice #2 lesson). No Kafka/event (synchronous SSE).
CREATE TABLE ai_mentor_sessions (
  id                BIGSERIAL PRIMARY KEY,
  user_id           BIGINT NOT NULL,
  content_id        BIGINT,
  question          TEXT NOT NULL,
  answer            TEXT NOT NULL DEFAULT '',
  context_snapshot  JSONB NOT NULL DEFAULT '{}',
  reference_links   JSONB NOT NULL DEFAULT '[]',
  provider          VARCHAR(16),
  status            VARCHAR(16) NOT NULL,
  error_code        VARCHAR(32),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_ai_mentor_status CHECK (status IN ('DONE','FAILED'))
);

-- 사용자별 멘토 이력 최신순(단발 Q&A, UNIQUE 불요).
CREATE INDEX idx_ai_mentor_user_created ON ai_mentor_sessions(user_id, created_at DESC);

CREATE TRIGGER ai_mentor_sessions_set_updated_at BEFORE UPDATE ON ai_mentor_sessions
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

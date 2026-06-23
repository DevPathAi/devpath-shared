-- MD2 Slice #6: AI code review results (async, one per sandbox run).
-- sandbox_session_id(sandbox-svc) / user_id(platform) / content_id(learning) are
-- cross-service logical references only - NO FK (service boundary; slice #2 lesson).
CREATE TABLE ai_code_reviews (
  id                  BIGSERIAL PRIMARY KEY,
  sandbox_session_id  BIGINT NOT NULL,
  user_id             BIGINT NOT NULL,
  content_id          BIGINT,
  status              VARCHAR(16) NOT NULL DEFAULT 'PENDING',
  provider            VARCHAR(16),
  confidence          INT,
  strengths           JSONB NOT NULL DEFAULT '[]',
  improvements        JSONB NOT NULL DEFAULT '[]',
  security            JSONB NOT NULL DEFAULT '[]',
  feedback            VARCHAR(8),
  error_code          VARCHAR(32),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_ai_code_reviews_session UNIQUE (sandbox_session_id),
  CONSTRAINT chk_ai_review_status CHECK (status IN ('PENDING','DONE','FAILED')),
  CONSTRAINT chk_ai_review_feedback CHECK (feedback IS NULL OR feedback IN ('UP','DOWN')),
  CONSTRAINT chk_ai_review_confidence CHECK (confidence IS NULL OR (confidence BETWEEN 0 AND 100))
);

CREATE INDEX idx_ai_reviews_user_created ON ai_code_reviews(user_id, created_at DESC);

CREATE TRIGGER ai_code_reviews_set_updated_at BEFORE UPDATE ON ai_code_reviews
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

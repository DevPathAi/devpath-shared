-- MD2 Slice #4: user content reading progress.
-- user_id is a logical platform users reference only; no cross-service FK.
CREATE TABLE user_content_progress (
  id           BIGSERIAL PRIMARY KEY,
  user_id      BIGINT NOT NULL,
  content_id   BIGINT NOT NULL REFERENCES contents(id) ON DELETE CASCADE,
  scroll_pct   DOUBLE PRECISION NOT NULL DEFAULT 0,
  dwell_sec    INT NOT NULL DEFAULT 0,
  completed_at TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_ucp_user_content UNIQUE (user_id, content_id),
  CONSTRAINT chk_ucp_scroll CHECK (scroll_pct >= 0 AND scroll_pct <= 1),
  CONSTRAINT chk_ucp_dwell CHECK (dwell_sec >= 0)
);

CREATE INDEX idx_ucp_user_updated ON user_content_progress(user_id, updated_at DESC);
CREATE INDEX idx_ucp_content ON user_content_progress(content_id);

CREATE TRIGGER user_content_progress_set_updated_at BEFORE UPDATE ON user_content_progress
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

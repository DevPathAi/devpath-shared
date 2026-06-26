-- MD3 Slice #9: LCS (learning context snapshots) — MVP Phase 1.
-- user_id / attached_to_id (community_questions) / content refs = logical references only; NO cross-service FK.
-- Snapshots are immutable after commit (no updated_at). Preferences are mutable (set_updated_at trigger).
-- recent_errors collection + 3-stage sanitize + realtime Kafka/Redis cache are Phase 2 (not in this migration).

CREATE TABLE learning_context_snapshots (
  id                BIGSERIAL PRIMARY KEY,
  user_id           BIGINT NOT NULL,
  purpose           VARCHAR(32) NOT NULL DEFAULT 'question_attachment',
  attached_to_type  VARCHAR(32),
  attached_to_id    BIGINT,
  content_snapshot  JSONB NOT NULL,
  visibility        VARCHAR(16) NOT NULL DEFAULT 'answerers_only',
  fields_included   JSONB NOT NULL DEFAULT '[]',
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_lcs_purpose CHECK (purpose IN ('question_attachment','analytics')),
  CONSTRAINT chk_lcs_visibility CHECK (visibility IN ('public','answerers_only','private')),
  CONSTRAINT chk_lcs_attached_type CHECK (attached_to_type IS NULL OR attached_to_type IN ('question','answer'))
);
CREATE INDEX idx_lcs_user ON learning_context_snapshots(user_id);
CREATE INDEX idx_lcs_attached ON learning_context_snapshots(attached_to_type, attached_to_id);
CREATE INDEX idx_lcs_created ON learning_context_snapshots(created_at DESC);

CREATE TABLE user_context_preferences (
  user_id                  BIGINT PRIMARY KEY,
  collect_current_content  BOOLEAN NOT NULL DEFAULT TRUE,
  collect_learning_path    BOOLEAN NOT NULL DEFAULT TRUE,
  collect_active_tags      BOOLEAN NOT NULL DEFAULT TRUE,
  collect_recent_errors    BOOLEAN NOT NULL DEFAULT FALSE,  -- 가장 민감 → 기본 OFF (Phase 2 활성)
  collect_tag_reputation   BOOLEAN NOT NULL DEFAULT TRUE,
  collect_level            BOOLEAN NOT NULL DEFAULT TRUE,
  default_visibility       VARCHAR(16) NOT NULL DEFAULT 'answerers_only',
  created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_ucp_visibility CHECK (default_visibility IN ('public','answerers_only','private'))
);
CREATE TRIGGER user_context_preferences_set_updated_at BEFORE UPDATE ON user_context_preferences
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- MD2 Slice #5: sandbox code execution sessions.
-- user_id(platform) / content_id, code_block_id(learning) are cross-service logical
-- references only - NO FK (service boundary; slice #2 lesson). code_blocks table absent.
CREATE TABLE sandbox_sessions (
  id              BIGSERIAL PRIMARY KEY,
  user_id         BIGINT NOT NULL,
  content_id      BIGINT,
  code_block_id   BIGINT,
  language        VARCHAR(16) NOT NULL,
  container_id    VARCHAR(128),
  status          VARCHAR(16) NOT NULL DEFAULT 'ALLOCATING',
  submitted_code  TEXT NOT NULL,
  stdout          TEXT,
  stderr          TEXT,
  exit_code       INT,
  cpu_ms_used     BIGINT,
  memory_mb_peak  INT,
  started_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  finished_at     TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_sandbox_language CHECK (language IN ('JAVA','NODE','PYTHON')),
  CONSTRAINT chk_sandbox_status CHECK (status IN ('ALLOCATING','RUNNING','COMPLETED','FAILED','KILLED'))
);

CREATE INDEX idx_sandbox_user_started ON sandbox_sessions(user_id, started_at DESC);

CREATE TRIGGER sandbox_sessions_set_updated_at BEFORE UPDATE ON sandbox_sessions
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

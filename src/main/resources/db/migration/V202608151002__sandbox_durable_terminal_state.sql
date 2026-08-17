-- ET8 phase 1: persist output truncation and install the expanded status guard
-- without scanning the whole sandbox_sessions table under ACCESS EXCLUSIVE.
ALTER TABLE sandbox_sessions
  ADD COLUMN output_truncated BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE sandbox_sessions
  ADD CONSTRAINT chk_sandbox_status_v2
  CHECK (status IN (
    'ALLOCATING',
    'RUNNING',
    'COMPLETED',
    'FAILED',
    'KILLED',
    'TIMED_OUT'
  )) NOT VALID;

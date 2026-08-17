-- ET8 phase 2: validation uses PostgreSQL's lighter validation lock. Only
-- after the scan succeeds do we briefly replace the legacy constraint name.
ALTER TABLE sandbox_sessions
  VALIDATE CONSTRAINT chk_sandbox_status_v2;

ALTER TABLE sandbox_sessions
  DROP CONSTRAINT chk_sandbox_status;

ALTER TABLE sandbox_sessions
  RENAME CONSTRAINT chk_sandbox_status_v2 TO chk_sandbox_status;

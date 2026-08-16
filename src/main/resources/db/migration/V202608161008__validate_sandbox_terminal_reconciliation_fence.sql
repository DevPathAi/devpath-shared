-- Complete the low-lock terminal-source constraint rollout separately from
-- the column-add migration.
ALTER TABLE sandbox_sessions
  VALIDATE CONSTRAINT chk_sandbox_terminal_source;

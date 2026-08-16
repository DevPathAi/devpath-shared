-- Reconciliation is deliberately two-phase. A different pod first records a
-- durable claim, then waits for the original process to renew or persist its
-- exact terminal result before inferring process loss.
ALTER TABLE sandbox_sessions
  ADD COLUMN reconciliation_token UUID,
  ADD COLUMN reconciliation_started_at TIMESTAMPTZ,
  ADD COLUMN terminal_source VARCHAR(16);

-- Nullable columns preserve rolling compatibility. NOT VALID avoids a table
-- scan under the migration lock while still rejecting every new invalid value.
ALTER TABLE sandbox_sessions
  ADD CONSTRAINT chk_sandbox_terminal_source
  CHECK (terminal_source IS NULL OR terminal_source IN ('RUNNER', 'RECONCILER'))
  NOT VALID;

-- This migration is deliberately non-transactional: PostgreSQL concurrent
-- index creation avoids blocking sandbox writers during the rollout.
CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS uq_sandbox_one_active_user
  ON sandbox_sessions (user_id)
  WHERE status IN ('ALLOCATING', 'RUNNING');

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_sandbox_active_lease
  ON sandbox_sessions (lease_expires_at, id)
  WHERE status IN ('ALLOCATING', 'RUNNING')
    AND lease_expires_at IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_sandbox_active_legacy
  ON sandbox_sessions (updated_at, id)
  WHERE status IN ('ALLOCATING', 'RUNNING')
    AND lease_expires_at IS NULL;

CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS uq_outbox_dedupe_key
  ON outbox (dedupe_key)
  WHERE dedupe_key IS NOT NULL;

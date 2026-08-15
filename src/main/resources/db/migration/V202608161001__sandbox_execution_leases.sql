-- ET8 hardening phase 1. Columns stay nullable so an old application pod can
-- overlap the rollout while new pods start writing durable execution leases.
ALTER TABLE sandbox_sessions
  ADD COLUMN owner_instance VARCHAR(128),
  ADD COLUMN lease_expires_at TIMESTAMPTZ;

-- The database unique index installed in phase 2 cannot be created while
-- historical duplicate active rows exist. Preserve the newest active row and
-- make every older duplicate explicitly terminal instead of deleting history.
WITH ranked_active AS (
  SELECT id,
         row_number() OVER (
           PARTITION BY user_id
           ORDER BY updated_at DESC, started_at DESC, id DESC
         ) AS active_rank
  FROM sandbox_sessions
  WHERE status IN ('ALLOCATING', 'RUNNING')
), duplicate_active AS (
  SELECT id
  FROM ranked_active
  WHERE active_rank > 1
)
UPDATE sandbox_sessions AS session
SET status = 'KILLED',
    finished_at = COALESCE(session.finished_at, now()),
    exit_code = COALESCE(session.exit_code, -1),
    stderr = concat_ws(
      E'\n',
      NULLIF(session.stderr, ''),
      'Recovered during one-active-run admission migration'
    )
FROM duplicate_active
WHERE session.id = duplicate_active.id;

-- Existing outbox rows remain untouched. New sandbox terminal events use a
-- deterministic key; the concurrent unique index in phase 2 makes retries
-- exactly-once at the outbox boundary.
ALTER TABLE outbox
  ADD COLUMN dedupe_key VARCHAR(200);

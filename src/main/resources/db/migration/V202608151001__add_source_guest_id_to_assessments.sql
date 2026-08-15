-- Guest claim idempotency key. Existing/member assessments remain NULL, while a claimed
-- guest assessment keeps its canonical UUID string as an immutable application identity.
ALTER TABLE assessments
  ADD COLUMN source_guest_id VARCHAR(36),
  ADD CONSTRAINT chk_assessments_source_guest_id_uuid CHECK (
    source_guest_id IS NULL
    OR source_guest_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
  ),
  ADD CONSTRAINT uq_assessments_source_guest_id UNIQUE (source_guest_id);

COMMENT ON COLUMN assessments.source_guest_id IS
  'Immutable guest assessment UUID used for claim idempotency; NULL for legacy/member assessments.';

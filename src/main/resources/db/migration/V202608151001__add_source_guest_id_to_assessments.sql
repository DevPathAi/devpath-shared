-- Guest claim idempotency key. Existing/member assessments remain NULL, while a claimed
-- guest assessment keeps its canonical UUID string as an immutable application identity.
ALTER TABLE assessments
  ADD COLUMN source_guest_id VARCHAR(36),
  ADD CONSTRAINT chk_assessments_source_guest_id_uuid CHECK (
    source_guest_id IS NULL
    OR source_guest_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
  ),
  ADD CONSTRAINT uq_assessments_source_guest_id UNIQUE (source_guest_id);

COMMENT ON COLUMN assessments.source_guest_id IS
  'Immutable guest assessment UUID used for claim idempotency; NULL for legacy/member assessments.';

-- A rolling deployment may bind one pre-migration claimed row from NULL to its guest UUID.
-- Once bound, the database rejects reassignment or clearing so ownership cannot drift.
CREATE FUNCTION prevent_assessments_source_guest_id_reassignment()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF OLD.source_guest_id IS NOT NULL
      AND NEW.source_guest_id IS DISTINCT FROM OLD.source_guest_id THEN
    RAISE EXCEPTION 'assessments.source_guest_id is immutable after binding'
      USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER assessments_source_guest_id_immutable
  BEFORE UPDATE OF source_guest_id ON assessments
  FOR EACH ROW EXECUTE FUNCTION prevent_assessments_source_guest_id_reassignment();

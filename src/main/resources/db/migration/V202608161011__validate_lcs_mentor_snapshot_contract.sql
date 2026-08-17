DO $migration$
DECLARE
  snapshot_table TEXT := format('%I.learning_context_snapshots', current_schema());
BEGIN
  IF to_regclass(snapshot_table) IS NULL THEN
    RETURN;
  END IF;

  EXECUTE format(
    'ALTER TABLE %s VALIDATE CONSTRAINT chk_lcs_purpose_v2', snapshot_table);
  EXECUTE format(
    'ALTER TABLE %s VALIDATE CONSTRAINT chk_lcs_mentor_private', snapshot_table);
  EXECUTE format(
    'ALTER TABLE %s VALIDATE CONSTRAINT chk_lcs_source_draft_id', snapshot_table);
  EXECUTE format(
    'ALTER TABLE %s RENAME CONSTRAINT chk_lcs_purpose_v2 TO chk_lcs_purpose',
    snapshot_table);
END
$migration$;

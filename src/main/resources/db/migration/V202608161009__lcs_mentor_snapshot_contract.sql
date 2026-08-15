-- ET9 expands the existing LCS snapshot table without rewriting historical rows.
-- Explicit schema binding prevents partial-schema verification from falling through
-- the search_path and mutating a different schema's LCS table.
DO $migration$
DECLARE
  schema_name TEXT := current_schema();
  snapshot_table TEXT := format('%I.learning_context_snapshots', current_schema());
BEGIN
  IF to_regclass(snapshot_table) IS NULL THEN
    RAISE NOTICE 'Skipping LCS Mentor contract: %.learning_context_snapshots is absent',
      schema_name;
    RETURN;
  END IF;

  EXECUTE format(
    'ALTER TABLE %s ADD COLUMN source_draft_id VARCHAR(41)', snapshot_table);

  -- NOT VALID guards still enforce every new row. Validation is separated so
  -- this catalog phase does not scan the table while writers are blocked.
  EXECUTE format(
    'ALTER TABLE %s '
      || 'ADD CONSTRAINT chk_lcs_purpose_v2 CHECK ('
      || 'purpose IN (''question_attachment'', ''analytics'', ''mentor_prompt'')) NOT VALID, '
      || 'ADD CONSTRAINT chk_lcs_mentor_private CHECK ('
      || 'purpose <> ''mentor_prompt'' OR ('
      || 'visibility = ''private'' AND attached_to_type IS NULL '
      || 'AND attached_to_id IS NULL AND source_draft_id IS NOT NULL)) NOT VALID, '
      || 'ADD CONSTRAINT chk_lcs_source_draft_id CHECK ('
      || 'source_draft_id IS NULL OR (purpose = ''mentor_prompt'' '
      || 'AND source_draft_id ~ '
      || '''^snap_[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'')) '
      || 'NOT VALID',
    snapshot_table);

  -- The v2 guard is active for new writes before the legacy guard is retired.
  EXECUTE format(
    'ALTER TABLE %s DROP CONSTRAINT chk_lcs_purpose', snapshot_table);

  EXECUTE format($ddl$
    CREATE FUNCTION %I.lcs_reject_committed_snapshot_update()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $trigger$
    BEGIN
      RAISE EXCEPTION 'learning context snapshots are immutable after commit'
        USING ERRCODE = '23514';
    END
    $trigger$
    $ddl$, schema_name);

  EXECUTE format(
    'CREATE TRIGGER learning_context_snapshots_reject_update '
      || 'BEFORE UPDATE ON %s FOR EACH ROW EXECUTE FUNCTION '
      || '%I.lcs_reject_committed_snapshot_update()',
    snapshot_table, schema_name);
END
$migration$;

DO $migration$
DECLARE
  schema_name TEXT := current_schema();
  assessment_table TEXT := format('%I.assessments', current_schema());
BEGIN
  IF to_regclass(assessment_table) IS NULL THEN
    RAISE NOTICE 'Skipping assessment guest-claim validation: %.assessments is absent', schema_name;
    RETURN;
  END IF;

  -- Validate in a separate migration so PostgreSQL uses its lower-lock validation path.
  -- The old validated case-insensitive guard remains installed until validation succeeds.
  EXECUTE format(
    'ALTER TABLE %s VALIDATE CONSTRAINT '
      || 'chk_assessments_source_guest_id_uuid_canonical',
    assessment_table);
  EXECUTE format(
    'ALTER TABLE %s DROP CONSTRAINT chk_assessments_source_guest_id_uuid',
    assessment_table);
  EXECUTE format(
    'ALTER TABLE %s RENAME CONSTRAINT '
      || 'chk_assessments_source_guest_id_uuid_canonical '
      || 'TO chk_assessments_source_guest_id_uuid',
    assessment_table);
END
$migration$;

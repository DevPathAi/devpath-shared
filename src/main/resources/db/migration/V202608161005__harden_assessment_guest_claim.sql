DO $migration$
DECLARE
  schema_name TEXT := current_schema();
  assessment_table TEXT := format('%I.assessments', current_schema());
  has_semantic_collision BOOLEAN;
BEGIN
  -- Bind every object to Flyway's current schema. Partial-schema migration tests must
  -- never fall through search_path and mutate public.assessments.
  IF to_regclass(assessment_table) IS NULL THEN
    RAISE NOTICE 'Skipping assessment guest-claim hardening: %.assessments is absent', schema_name;
    RETURN;
  END IF;

  -- Preserve the already-published V202608151001 checksum and harden its guest identity
  -- contract append-only. NOT VALID avoids an immediate full-table scan while rejecting
  -- non-canonical values from new inserts and updates as soon as this migration lands.
  EXECUTE format(
    'ALTER TABLE %s ADD CONSTRAINT chk_assessments_source_guest_id_uuid_canonical '
      || 'CHECK (source_guest_id IS NULL OR source_guest_id ~ '
      || '''^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'') '
      || 'NOT VALID',
    assessment_table);

  -- The historical case-insensitive guard allowed upper/lower variants to coexist under
  -- a case-sensitive UNIQUE constraint. Abort instead of silently merging two assessments.
  EXECUTE format(
    'SELECT EXISTS (SELECT lower(source_guest_id) FROM %s '
      || 'WHERE source_guest_id IS NOT NULL GROUP BY lower(source_guest_id) '
      || 'HAVING count(*) > 1)',
    assessment_table)
  INTO has_semantic_collision;
  IF has_semantic_collision THEN
    RAISE EXCEPTION 'case-insensitive duplicate assessments.source_guest_id values require remediation'
      USING ERRCODE = '23505';
  END IF;

  EXECUTE format(
    'UPDATE %s SET source_guest_id = lower(source_guest_id) '
      || 'WHERE source_guest_id IS NOT NULL '
      || 'AND source_guest_id <> lower(source_guest_id)',
    assessment_table);

  -- A rolling deployment may bind one pre-migration row from NULL to its guest UUID.
  -- Once bound, the database rejects reassignment or clearing so ownership cannot drift.
  EXECUTE format($statement$
    CREATE FUNCTION %I.prevent_assessments_source_guest_id_reassignment()
    RETURNS TRIGGER LANGUAGE plpgsql AS $function$
    BEGIN
      IF OLD.source_guest_id IS NOT NULL
          AND NEW.source_guest_id IS DISTINCT FROM OLD.source_guest_id THEN
        RAISE EXCEPTION 'assessments.source_guest_id is immutable after binding'
          USING ERRCODE = '23514';
      END IF;
      RETURN NEW;
    END;
    $function$
  $statement$, schema_name);

  EXECUTE format(
    'CREATE TRIGGER assessments_source_guest_id_immutable '
      || 'BEFORE UPDATE OF source_guest_id ON %s FOR EACH ROW '
      || 'EXECUTE FUNCTION %I.prevent_assessments_source_guest_id_reassignment()',
    assessment_table, schema_name);
END
$migration$;

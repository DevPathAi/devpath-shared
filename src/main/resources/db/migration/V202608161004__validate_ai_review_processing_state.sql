-- Complete the low-lock status expansion in Flyway's current schema.
DO $migration$
DECLARE
  review_table TEXT := format('%I.ai_code_reviews', current_schema());
BEGIN
  IF to_regclass(review_table) IS NULL THEN
    RETURN;
  END IF;

  EXECUTE format(
    'ALTER TABLE %s VALIDATE CONSTRAINT chk_ai_review_status_v2', review_table);
  EXECUTE format(
    'ALTER TABLE %s VALIDATE CONSTRAINT chk_ai_review_processing_lease', review_table);
  EXECUTE format(
    'ALTER TABLE %s DROP CONSTRAINT chk_ai_review_status', review_table);
  EXECUTE format(
    'ALTER TABLE %s RENAME CONSTRAINT chk_ai_review_status_v2 TO chk_ai_review_status',
    review_table);
END
$migration$;

-- ET8 Review consumes sandbox.run.submitted with at-least-once delivery.
-- Keep only event metadata here: the Kafka payload can contain submitted code and must not be copied.
-- Every object is explicitly bound to Flyway's current schema so partial-schema migration tests
-- cannot fall through the search_path and mutate public.ai_code_reviews.

DO $migration$
DECLARE
  schema_name TEXT := current_schema();
  review_table TEXT := format('%I.ai_code_reviews', current_schema());
BEGIN
  IF to_regclass(review_table) IS NULL THEN
    RAISE NOTICE 'Skipping AI review idempotency objects: %.ai_code_reviews is absent', schema_name;
    RETURN;
  END IF;

  EXECUTE format(
    'ALTER TABLE %s ADD COLUMN processing_token UUID, '
      || 'ADD COLUMN lease_expires_at TIMESTAMPTZ, ADD COLUMN source_event_id UUID',
    review_table);

  -- Install expanded guards without scanning the table or removing the legacy guard yet.
  EXECUTE format(
    'ALTER TABLE %s ADD CONSTRAINT chk_ai_review_status_v2 '
      || 'CHECK (status IN (''PENDING'',''PROCESSING'',''DONE'',''FAILED'')) NOT VALID, '
      || 'ADD CONSTRAINT chk_ai_review_processing_lease CHECK ('
      || '(status = ''PROCESSING'' AND processing_token IS NOT NULL '
      || 'AND lease_expires_at IS NOT NULL) OR '
      || '(status <> ''PROCESSING'' AND processing_token IS NULL '
      || 'AND lease_expires_at IS NULL)) NOT VALID',
    review_table);

  EXECUTE format(
    'CREATE TABLE %I.ai_review_event_inbox ('
      || 'event_id UUID PRIMARY KEY, sandbox_session_id BIGINT NOT NULL, '
      || 'first_received_at TIMESTAMPTZ NOT NULL DEFAULT now(), '
      || 'last_received_at TIMESTAMPTZ NOT NULL DEFAULT now(), '
      || 'delivery_count BIGINT NOT NULL DEFAULT 1, processed_at TIMESTAMPTZ, '
      || 'CONSTRAINT chk_ai_review_inbox_delivery_count CHECK (delivery_count > 0))',
    schema_name);

  EXECUTE format(
    'CREATE INDEX idx_ai_review_inbox_session ON %I.ai_review_event_inbox(sandbox_session_id)',
    schema_name);
  EXECUTE format(
    'CREATE INDEX idx_ai_reviews_processing_lease ON %s(lease_expires_at) '
      || 'WHERE status = ''PROCESSING''',
    review_table);
END
$migration$;

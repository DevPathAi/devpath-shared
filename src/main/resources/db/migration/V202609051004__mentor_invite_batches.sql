-- 일일 멘토 초대 배치와 실제 메일 전송 성공 감사.
DO $migration$
DECLARE
  target_schema TEXT := current_schema();
BEGIN
  IF to_regclass(format('%I.users', target_schema)) IS NULL
      OR to_regclass(format('%I.mentor_access', target_schema)) IS NULL THEN
    RETURN;
  END IF;

  EXECUTE format(
    'CREATE TABLE %I.mentor_invite_batches ('
      || 'id BIGSERIAL PRIMARY KEY, '
      || 'batch_date DATE NOT NULL UNIQUE, '
      || 'status VARCHAR(16) NOT NULL, '
      || 'chunk_size INTEGER NOT NULL, '
      || 'daily_cap INTEGER NOT NULL, '
      || 'activated_count INTEGER NOT NULL DEFAULT 0, '
      || 'started_at TIMESTAMPTZ NOT NULL DEFAULT now(), '
      || 'completed_at TIMESTAMPTZ, '
      || 'failure_reason VARCHAR(255), '
      || 'CONSTRAINT chk_mentor_batch_status CHECK (status IN (''RUNNING'',''COMPLETED'',''FAILED'')), '
      || 'CONSTRAINT chk_mentor_batch_limits CHECK ('
      || 'chunk_size BETWEEN 1 AND 500 AND daily_cap BETWEEN 1 AND 5000 '
      || 'AND activated_count BETWEEN 0 AND daily_cap), '
      || 'CONSTRAINT chk_mentor_batch_completion CHECK ('
      || '(status = ''RUNNING'' AND completed_at IS NULL) OR '
      || '(status IN (''COMPLETED'',''FAILED'') AND completed_at IS NOT NULL)))',
    target_schema);

  EXECUTE format(
    'ALTER TABLE %I.mentor_access ADD CONSTRAINT fk_mentor_access_batch '
      || 'FOREIGN KEY (batch_id) REFERENCES %I.mentor_invite_batches(id)',
    target_schema, target_schema);

  EXECUTE format(
    'CREATE TABLE %I.mentor_invite_deliveries ('
      || 'id BIGSERIAL PRIMARY KEY, '
      || 'event_id UUID NOT NULL UNIQUE, '
      || 'user_id BIGINT NOT NULL REFERENCES %I.users(id), '
      || 'batch_id BIGINT REFERENCES %I.mentor_invite_batches(id), '
      || 'provider_message_id VARCHAR(255) NOT NULL, '
      || 'sent_at TIMESTAMPTZ NOT NULL DEFAULT now())',
    target_schema, target_schema, target_schema);

  EXECUTE format(
    'CREATE INDEX idx_mentor_invite_deliveries_batch_sent '
      || 'ON %I.mentor_invite_deliveries (batch_id,sent_at)',
    target_schema);
END
$migration$;

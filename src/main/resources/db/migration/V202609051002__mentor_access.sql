-- 일반 계정 접근과 AI 멘토 접근을 분리한다.
-- 기존 beta allowlist 승인자는 ACTIVE로 백필하고, 신규 사용자는 플랫폼이 WAITLISTED로 등록한다.
DO $migration$
DECLARE
  target_schema TEXT := current_schema();
  has_users BOOLEAN := to_regclass(format('%I.users', current_schema())) IS NOT NULL;
  has_allowlist BOOLEAN := to_regclass(format('%I.beta_allowlist', current_schema())) IS NOT NULL;
BEGIN
  IF NOT has_users AND NOT has_allowlist THEN
    RETURN;
  ELSIF NOT has_users OR NOT has_allowlist THEN
    RAISE EXCEPTION
      'asymmetric mentor access prerequisites in schema % (users: %, beta_allowlist: %)',
      target_schema, has_users, has_allowlist;
  END IF;

  EXECUTE format(
    'CREATE TABLE %I.mentor_access ('
      || 'id BIGSERIAL PRIMARY KEY, '
      || 'user_id BIGINT NOT NULL UNIQUE REFERENCES %I.users(id) ON DELETE CASCADE, '
      || 'status VARCHAR(16) NOT NULL, '
      || 'source VARCHAR(16) NOT NULL, '
      || 'waitlisted_at TIMESTAMPTZ NOT NULL DEFAULT now(), '
      || 'activated_at TIMESTAMPTZ, '
      || 'batch_id BIGINT, '
      || 'invite_code_id BIGINT, '
      || 'created_at TIMESTAMPTZ NOT NULL DEFAULT now(), '
      || 'updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), '
      || 'CONSTRAINT chk_mentor_access_status CHECK (status IN (''WAITLISTED'',''ACTIVE'')), '
      || 'CONSTRAINT chk_mentor_access_source CHECK (source IN (''SELF'',''INVITE_CODE'',''ADMIN'',''BATCH'')), '
      || 'CONSTRAINT chk_mentor_access_activation CHECK ('
      || '(status = ''WAITLISTED'' AND activated_at IS NULL) OR '
      || '(status = ''ACTIVE'' AND activated_at IS NOT NULL)))',
    target_schema, target_schema);

  EXECUTE format(
    'CREATE INDEX idx_mentor_access_waitlist '
      || 'ON %I.mentor_access (status, waitlisted_at, id)',
    target_schema);

  EXECUTE format(
    'INSERT INTO %I.mentor_access(user_id,status,source,waitlisted_at,activated_at) '
      || 'SELECT u.id,''ACTIVE'',''ADMIN'',now(),now() '
      || 'FROM %I.users u JOIN %I.beta_allowlist b ON lower(b.email)=lower(u.email) '
      || 'WHERE u.status=''ACTIVE'' AND u.deleted_at IS NULL '
      || 'ON CONFLICT (user_id) DO NOTHING',
    target_schema, target_schema, target_schema);
END
$migration$;

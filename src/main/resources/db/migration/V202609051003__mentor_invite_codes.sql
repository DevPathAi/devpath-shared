-- 심사자·멘토가 대기열을 건너뛸 수 있는 1회 노출형 코드.
-- 원문 코드는 어느 테이블에도 저장하지 않고 keyed HMAC의 64자 hex만 저장한다.
DO $migration$
DECLARE
  target_schema TEXT := current_schema();
  has_users BOOLEAN := to_regclass(format('%I.users', current_schema())) IS NOT NULL;
  has_mentor_access BOOLEAN :=
    to_regclass(format('%I.mentor_access', current_schema())) IS NOT NULL;
BEGIN
  IF NOT has_users AND NOT has_mentor_access THEN
    RETURN;
  ELSIF NOT has_users OR NOT has_mentor_access THEN
    RAISE EXCEPTION
      'asymmetric mentor invite code prerequisites in schema % (users: %, mentor_access: %)',
      target_schema, has_users, has_mentor_access;
  END IF;

  EXECUTE format(
    'ALTER TABLE %I.mentor_access ADD COLUMN version BIGINT NOT NULL DEFAULT 0',
    target_schema);

  EXECUTE format(
    'CREATE TABLE %I.mentor_invite_codes ('
      || 'id BIGSERIAL PRIMARY KEY, '
      || 'code_hash CHAR(64) NOT NULL UNIQUE, '
      || 'label VARCHAR(100) NOT NULL, '
      || 'audience VARCHAR(16) NOT NULL, '
      || 'cohort VARCHAR(64) NOT NULL, '
      || 'expires_at TIMESTAMPTZ NOT NULL, '
      || 'max_redemptions INTEGER NOT NULL, '
      || 'redemption_count INTEGER NOT NULL DEFAULT 0, '
      || 'enabled BOOLEAN NOT NULL DEFAULT true, '
      || 'created_by BIGINT NOT NULL REFERENCES %I.users(id), '
      || 'created_at TIMESTAMPTZ NOT NULL DEFAULT now(), '
      || 'disabled_by BIGINT REFERENCES %I.users(id), '
      || 'disabled_at TIMESTAMPTZ, '
      || 'disable_reason VARCHAR(255), '
      || 'CONSTRAINT chk_mentor_invite_code_hash CHECK (code_hash ~ ''^[0-9a-f]{64}$''), '
      || 'CONSTRAINT chk_mentor_invite_audience CHECK (audience IN (''JUDGE'',''MENTOR'')), '
      || 'CONSTRAINT chk_mentor_invite_max CHECK (max_redemptions BETWEEN 1 AND 1000), '
      || 'CONSTRAINT chk_mentor_invite_count CHECK ('
      || 'redemption_count BETWEEN 0 AND max_redemptions), '
      || 'CONSTRAINT chk_mentor_invite_disabled CHECK ('
      || '(enabled AND disabled_at IS NULL AND disabled_by IS NULL) OR '
      || '(NOT enabled AND disabled_at IS NOT NULL AND disabled_by IS NOT NULL)))',
    target_schema, target_schema, target_schema);

  EXECUTE format(
    'CREATE TABLE %I.mentor_invite_code_redemptions ('
      || 'id BIGSERIAL PRIMARY KEY, '
      || 'invite_code_id BIGINT NOT NULL REFERENCES %I.mentor_invite_codes(id), '
      || 'user_id BIGINT NOT NULL UNIQUE REFERENCES %I.users(id), '
      || 'redeemed_at TIMESTAMPTZ NOT NULL DEFAULT now(), '
      || 'UNIQUE(invite_code_id,user_id))',
    target_schema, target_schema, target_schema);

  EXECUTE format(
    'ALTER TABLE %I.mentor_access ADD CONSTRAINT fk_mentor_access_invite_code '
      || 'FOREIGN KEY (invite_code_id) REFERENCES %I.mentor_invite_codes(id)',
    target_schema, target_schema);

  EXECUTE format(
    'CREATE INDEX idx_mentor_invite_codes_active '
      || 'ON %I.mentor_invite_codes (enabled,expires_at,id)',
    target_schema);
END
$migration$;

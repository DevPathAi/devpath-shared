-- Home의 익명 문의·오류 신고를 기존 support_requests 운영 큐에 합친다.
-- 부분 스키마 업그레이드 테스트와 서비스별 최소 스키마에서는 대상 테이블이 없을 수 있다.
-- unqualified ALTER가 search_path의 public 테이블로 새지 않도록 current_schema에 명시 바인딩한다.
DO $migration$
DECLARE
  target_schema TEXT := current_schema();
BEGIN
  IF to_regclass(format('%I.support_requests', target_schema)) IS NULL THEN
    RETURN;
  END IF;

  EXECUTE format(
    'ALTER TABLE %I.support_requests '
      || 'ALTER COLUMN reporter_id DROP NOT NULL, '
      || 'ADD COLUMN source VARCHAR(24) NOT NULL DEFAULT ''AUTHENTICATED_APP'', '
      || 'ADD COLUMN contact_email VARCHAR(254), '
      || 'ADD COLUMN privacy_consent_at TIMESTAMPTZ',
    target_schema);

  EXECUTE format(
    'ALTER TABLE %I.support_requests '
      || 'ADD CONSTRAINT chk_support_requests_source_identity CHECK ('
      || '(source = ''AUTHENTICATED_APP'' AND reporter_id IS NOT NULL '
      || 'AND contact_email IS NULL AND privacy_consent_at IS NULL) OR '
      || '(source = ''PUBLIC_HOME'' AND reporter_id IS NULL '
      || 'AND contact_email IS NOT NULL AND btrim(contact_email) <> '''' '
      || 'AND privacy_consent_at IS NOT NULL))',
    target_schema);

  EXECUTE format(
    'CREATE INDEX idx_support_requests_source_status_id '
      || 'ON %I.support_requests (source, status, id DESC)',
    target_schema);
END
$migration$;

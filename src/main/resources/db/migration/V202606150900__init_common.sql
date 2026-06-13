-- 공통 규약: 모든 테이블은 snake_case, created_at/updated_at(timestamptz) audit 컬럼을 가진다.
-- updated_at 자동 갱신 트리거 함수.
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

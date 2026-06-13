-- W1 범위: 가입에 필요한 최소 골격. W2 OAuth에서 확장한다.
CREATE TABLE users (
  id             BIGSERIAL PRIMARY KEY,
  github_id      BIGINT UNIQUE,
  status         VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_active_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER users_set_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

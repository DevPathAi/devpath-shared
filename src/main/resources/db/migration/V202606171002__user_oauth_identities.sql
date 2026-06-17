-- OAuth provider 신원 + 암호화된 provider 토큰. 로그인 조회는 (provider, provider_user_id).
CREATE TABLE user_oauth_identities (
  id                      BIGSERIAL PRIMARY KEY,
  user_id                 BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider                VARCHAR(20) NOT NULL,
  provider_user_id        VARCHAR(255) NOT NULL,
  access_token_encrypted  TEXT,
  refresh_token_encrypted TEXT,
  scope                   VARCHAR(255),
  linked_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_oauth_provider CHECK (provider IN ('GITHUB', 'GOOGLE', 'KAKAO'))
);
CREATE UNIQUE INDEX uq_oauth_provider_user ON user_oauth_identities(provider, provider_user_id);
CREATE INDEX idx_oauth_user ON user_oauth_identities(user_id);
CREATE TRIGGER user_oauth_identities_set_updated_at BEFORE UPDATE ON user_oauth_identities
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

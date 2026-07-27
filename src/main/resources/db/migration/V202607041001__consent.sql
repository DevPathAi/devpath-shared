ALTER TABLE users ADD COLUMN consent_status varchar(20) NOT NULL DEFAULT 'PENDING';
ALTER TABLE users ADD COLUMN birth_year int;
ALTER TABLE users ADD COLUMN deleted_at timestamptz;

CREATE TABLE user_consents (
  id bigserial PRIMARY KEY,
  user_id bigint NOT NULL,
  type varchar(20) NOT NULL,
  version varchar(20) NOT NULL,
  agreed boolean NOT NULL,
  agreed_at timestamptz NOT NULL DEFAULT now(),
  revoked_at timestamptz
);
CREATE INDEX idx_user_consents_user ON user_consents(user_id);

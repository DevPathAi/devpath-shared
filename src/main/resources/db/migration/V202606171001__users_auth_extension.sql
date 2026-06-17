-- 슬라이스 #1: W1 users 골격을 인증/온보딩 도메인으로 확장한다 (02_ERD §1).
-- GitHub 신원은 user_oauth_identities로 이관하므로 users.github_id는 제거한다.
ALTER TABLE users
  ADD COLUMN email             VARCHAR(255),
  ADD COLUMN nickname          VARCHAR(100),
  ADD COLUMN role              VARCHAR(20) NOT NULL DEFAULT 'LEARNER',
  ADD COLUMN onboarding_status VARCHAR(20) NOT NULL DEFAULT 'PENDING';

ALTER TABLE users ADD CONSTRAINT uq_users_email UNIQUE (email);
ALTER TABLE users ADD CONSTRAINT chk_users_role
  CHECK (role IN ('LEARNER', 'ADMIN'));
ALTER TABLE users ADD CONSTRAINT chk_users_onboarding_status
  CHECK (onboarding_status IN ('PENDING', 'IN_PROGRESS', 'DONE'));

ALTER TABLE users DROP COLUMN github_id;

CREATE INDEX idx_users_onboarding_status ON users(onboarding_status);

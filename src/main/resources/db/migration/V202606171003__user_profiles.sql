-- 사용자 프로필. learning_goal/target_track은 온보딩(#2)에서 채우므로 nullable.
CREATE TABLE user_profiles (
  user_id          BIGINT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  avatar           VARCHAR(512),
  bio              TEXT,
  learning_goal    VARCHAR(20),
  target_track     VARCHAR(20),
  experience_years INT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_learning_goal CHECK (
    learning_goal IS NULL OR learning_goal IN ('JOB', 'CAREER_CHANGE', 'UPSKILL', 'SIDE_PROJECT')),
  CONSTRAINT chk_target_track CHECK (
    target_track IS NULL OR target_track IN ('BACKEND_SPRING', 'FRONTEND_REACT', 'MOBILE_FLUTTER', 'DEVOPS', 'FULLSTACK'))
);
CREATE TRIGGER user_profiles_set_updated_at BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

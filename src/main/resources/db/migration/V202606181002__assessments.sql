-- 슬라이스 #2: 진단 세션 (02_ERD §3). 비회원은 user_id NULL, claim 시 결합. 시작 난이도 0.3.
CREATE TABLE assessments (
  id                 BIGSERIAL PRIMARY KEY,
  user_id            BIGINT REFERENCES users(id) ON DELETE CASCADE,
  track              VARCHAR(20) NOT NULL,
  status             VARCHAR(20) NOT NULL DEFAULT 'IN_PROGRESS',
  current_difficulty DOUBLE PRECISION NOT NULL DEFAULT 0.3,
  bloom_distribution JSONB,
  started_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at       TIMESTAMPTZ,
  CONSTRAINT chk_assessments_track CHECK (
    track IN ('BACKEND_SPRING', 'FRONTEND_REACT', 'MOBILE_FLUTTER', 'DEVOPS', 'FULLSTACK')),
  CONSTRAINT chk_assessments_status CHECK (
    status IN ('IN_PROGRESS', 'COMPLETED', 'ABANDONED')),
  CONSTRAINT chk_assessments_difficulty CHECK (
    current_difficulty >= 0.0 AND current_difficulty <= 1.0)
);
CREATE INDEX idx_assessments_user_id ON assessments(user_id);

-- 슬라이스 #2: 진단 문항 뱅크 (02_ERD §3). Bloom 태깅·난이도·개념 태그.
CREATE TABLE question_bank (
  id            BIGSERIAL PRIMARY KEY,
  track         VARCHAR(20) NOT NULL,
  question_type VARCHAR(20) NOT NULL,
  content       TEXT NOT NULL,
  options       JSONB,
  answer_key    JSONB NOT NULL,
  bloom_level   VARCHAR(20) NOT NULL,
  difficulty    DOUBLE PRECISION NOT NULL,
  concept_tags  JSONB,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_qb_track CHECK (
    track IN ('BACKEND_SPRING', 'FRONTEND_REACT', 'MOBILE_FLUTTER', 'DEVOPS', 'FULLSTACK')),
  CONSTRAINT chk_qb_question_type CHECK (
    question_type IN ('MCQ', 'CODE_READING', 'SHORT_ANSWER')),
  CONSTRAINT chk_qb_bloom_level CHECK (
    bloom_level IN ('REMEMBER', 'UNDERSTAND', 'APPLY', 'ANALYZE', 'EVALUATE', 'CREATE')),
  CONSTRAINT chk_qb_difficulty CHECK (difficulty >= 0.0 AND difficulty <= 1.0)
);
CREATE INDEX idx_question_bank_track_difficulty ON question_bank(track, difficulty);
CREATE TRIGGER question_bank_set_updated_at BEFORE UPDATE ON question_bank
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

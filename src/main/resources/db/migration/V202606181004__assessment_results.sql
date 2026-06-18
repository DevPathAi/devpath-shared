-- 슬라이스 #2: 진단 결과 (02_ERD §3). assessment와 1:1. diagnosed_level=JUNIOR/MID/SENIOR.
CREATE TABLE assessment_results (
  assessment_id     BIGINT PRIMARY KEY REFERENCES assessments(id) ON DELETE CASCADE,
  diagnosed_level   VARCHAR(20) NOT NULL,
  concept_scores    JSONB,
  strength_concepts JSONB,
  weakness_concepts JSONB,
  confidence_weight DOUBLE PRECISION,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_assessment_results_level CHECK (
    diagnosed_level IN ('JUNIOR', 'MID', 'SENIOR')),
  CONSTRAINT chk_ar_confidence CHECK (
    confidence_weight IS NULL OR (confidence_weight >= 0.0 AND confidence_weight <= 1.0))
);

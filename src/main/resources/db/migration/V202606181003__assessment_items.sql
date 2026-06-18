-- 슬라이스 #2: 진단 출제·응답 항목 (02_ERD §3). skipped='잘 모르겠어요'.
CREATE TABLE assessment_items (
  id               BIGSERIAL PRIMARY KEY,
  assessment_id    BIGINT NOT NULL REFERENCES assessments(id) ON DELETE CASCADE,
  question_bank_id BIGINT NOT NULL REFERENCES question_bank(id),
  order_num        INT NOT NULL,
  presented_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  answered_at      TIMESTAMPTZ,
  answer           JSONB,
  is_correct       BOOLEAN,
  skipped          BOOLEAN NOT NULL DEFAULT FALSE,
  time_spent_sec   INT,
  CONSTRAINT uq_assessment_items_order UNIQUE (assessment_id, order_num),
  CONSTRAINT chk_ai_order CHECK (order_num > 0),
  CONSTRAINT chk_ai_time CHECK (time_spent_sec IS NULL OR time_spent_sec >= 0)
);
CREATE INDEX idx_assessment_items_assessment ON assessment_items(assessment_id);

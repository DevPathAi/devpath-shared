-- 배지 카탈로그(참조 데이터). code가 코드의 안정키.
CREATE TABLE badges (
  id          BIGSERIAL PRIMARY KEY,
  code        VARCHAR(32)  NOT NULL UNIQUE,   -- FIRST_QUESTION 등
  name        VARCHAR(64)  NOT NULL,          -- 한글 배지명
  tier        VARCHAR(8)   NOT NULL,          -- BRONZE|SILVER|GOLD
  criteria    VARCHAR(255) NOT NULL,          -- 조건 원문
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
  CONSTRAINT chk_badge_tier CHECK (tier IN ('BRONZE','SILVER','GOLD'))
);

-- 사용자 보유 배지(멱등 수여 — PK가 중복 방지).
CREATE TABLE user_badges (
  user_id    BIGINT      NOT NULL,            -- platform users 논리 참조(FK 없음)
  badge_id   BIGINT      NOT NULL REFERENCES badges(id),
  awarded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, badge_id)
);
CREATE INDEX idx_user_badges_user ON user_badges (user_id, awarded_at DESC);

-- Bronze 9종 시드(설계문 20 §3.3).
INSERT INTO badges (code, name, tier, criteria) VALUES
  ('FIRST_QUESTION','첫 질문','BRONZE','질문 작성'),
  ('FIRST_ANSWER','첫 답변','BRONZE','답변 작성'),
  ('STUDENT','학생','BRONZE','질문 1개가 +1 이상'),
  ('TEACHER','선생','BRONZE','답변 1개가 +1 이상'),
  ('PHILANTHROPIST','자선가','BRONZE','평판 15 도달'),
  ('CRITIC','비평가','BRONZE','downvote 1회 행사'),
  ('FIRST_STEP','첫 걸음','BRONZE','프로필 작성 완료'),
  ('EDITOR','편집자','BRONZE','글 편집 1회'),
  ('COMMUNITY','커뮤니티','BRONZE','30일 연속 방문');

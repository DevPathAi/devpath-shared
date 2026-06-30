-- 평판 원장(append-only): 감사 + 일일상한 산출 + 투표변경 역산 근거.
CREATE TABLE reputation_events (
  id          BIGSERIAL PRIMARY KEY,
  user_id     BIGINT      NOT NULL,            -- 평판 귀속 대상(수혜자)
  actor_id    BIGINT,                          -- 유발자(투표자/채택자) — 역산 매칭용, 시스템이면 NULL
  delta       INT         NOT NULL,            -- 실제 반영된 값(상한 적용 후)
  reason      VARCHAR(32) NOT NULL,            -- UPVOTE_Q|UPVOTE_A|ACCEPTED|ACCEPT_BONUS|DOWNVOTE_RECEIVED|DOWNVOTE_CAST
  source_type VARCHAR(16) NOT NULL,            -- POST|ANSWER
  source_id   BIGINT      NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_repevent_user_day ON reputation_events (user_id, reason, created_at);
CREATE INDEX idx_repevent_actor_src ON reputation_events (actor_id, source_type, source_id);

-- 총점(비정규화, 빠른 읽기/레벨 게이트).
CREATE TABLE user_reputation (
  user_id    BIGINT PRIMARY KEY,
  total      INT NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 태그별 평판.
CREATE TABLE user_tag_reputation (
  user_id BIGINT NOT NULL,
  tag_id  BIGINT NOT NULL,
  score   INT NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id, tag_id)
);

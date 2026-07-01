-- 담합(sockpuppet) 의심 감사 로그. 기록만 — 실제 제재는 후속 moderation.
CREATE TABLE vote_abuse_suspicions (
  id             BIGSERIAL PRIMARY KEY,
  actor_id       BIGINT      NOT NULL,          -- 의심 투표자
  target_user_id BIGINT      NOT NULL,          -- 반복 수혜자
  reason         VARCHAR(32) NOT NULL,          -- REPEAT_UPVOTE (향후 확장)
  evidence_count INT         NOT NULL,          -- 탐지 시점 누적 근거 수
  detected_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_vote_abuse UNIQUE (actor_id, target_user_id, reason)
);
CREATE INDEX idx_vote_abuse_target ON vote_abuse_suspicions (target_user_id, detected_at DESC);

-- 학습 스트릭(연속 활동 일수). owner: devpath-learning-svc.
CREATE TABLE user_streak (
  user_id          BIGINT PRIMARY KEY,          -- platform users 논리 참조(FK 없음)
  current_days     INT NOT NULL DEFAULT 0,
  longest_days     INT NOT NULL DEFAULT 0,
  last_active_date DATE,
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

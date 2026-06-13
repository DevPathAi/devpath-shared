-- 정보통신망법 §29: 3년 미이용 사용자 분리보관.
CREATE TABLE dormant_user_archives (
  id          BIGSERIAL PRIMARY KEY,
  user_id     BIGINT NOT NULL REFERENCES users(id),
  archived_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  reason      VARCHAR(50) NOT NULL DEFAULT 'INACTIVE_3Y',
  payload     JSONB NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_dormant_user ON dormant_user_archives(user_id);

-- 분리보관 배치 스케줄러 실행 추적 메타.
CREATE TABLE dormant_archive_runs (
  id             BIGSERIAL PRIMARY KEY,
  ran_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  archived_count INT NOT NULL DEFAULT 0,
  status         VARCHAR(20) NOT NULL DEFAULT 'SUCCESS'
);

-- 정체(3일 미활동) 재참여 알림 재발행 방지 마커. owner: devpath-learning-svc.
-- 발행 시 now() 세팅, 유저 재활성 시 NULL 리셋 → 정체 에피소드당 정확히 1회 발행.
ALTER TABLE user_streak ADD COLUMN stagnation_notified_at TIMESTAMPTZ;

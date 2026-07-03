-- 주간 리포트 이력(재발송·다시보기 대비). owner: devpath-notification-svc.
CREATE TABLE weekly_report (
  id            BIGSERIAL PRIMARY KEY,
  user_id       BIGINT NOT NULL,
  week_of       DATE NOT NULL,               -- 해당 주 일요일 날짜
  payload       JSONB NOT NULL,              -- progress.report.generated 이벤트 payload 스냅샷
  generated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  email_sent_at TIMESTAMPTZ,
  push_sent_at  TIMESTAMPTZ
);
CREATE UNIQUE INDEX idx_weekly_report_user_week ON weekly_report (user_id, week_of);

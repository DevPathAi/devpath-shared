-- 알림 수신 설정(timezone은 Build 2에서 사용, 나머지 컬럼은 Build 3에서 사용). owner: devpath-notification-svc.
CREATE TABLE user_notification_prefs (
  user_id                     BIGINT PRIMARY KEY,
  timezone                    VARCHAR(64) NOT NULL DEFAULT 'Asia/Seoul',
  preferred_time_slot         VARCHAR(5)  NOT NULL DEFAULT '19:00',
  reminder_enabled            BOOLEAN NOT NULL DEFAULT true,
  weekly_report_email_enabled BOOLEAN NOT NULL DEFAULT true,
  updated_at                  TIMESTAMPTZ NOT NULL DEFAULT now()
);

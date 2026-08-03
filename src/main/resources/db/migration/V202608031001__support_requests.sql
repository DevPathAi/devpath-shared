-- 오류 신고·문의. ③ community_reports 와 별개다 — 대상이 콘텐츠가 아니라 서비스 자체라
-- target_type/1인1회 UNIQUE/콘텐츠 위반 category 가 모두 맞지 않는다.
CREATE TABLE support_requests (
  id           BIGSERIAL PRIMARY KEY,
  reporter_id  BIGINT       NOT NULL,
  type         VARCHAR(16)  NOT NULL,     -- ERROR | INQUIRY
  title        VARCHAR(200) NOT NULL,
  body         TEXT         NOT NULL,
  page_path    VARCHAR(512),              -- 제보 시점 라우트(쿼리스트링 제거)
  app_version  VARCHAR(32),
  user_agent   VARCHAR(512),
  viewport     VARCHAR(32),               -- "1920x1080"
  trace_id     VARCHAR(64),
  error_code   VARCHAR(64),
  occurred_at  TIMESTAMPTZ,               -- 사용자 체감 발생 시각(클라 제공)
  status       VARCHAR(16)  NOT NULL DEFAULT 'OPEN',
  admin_note   TEXT,
  handled_by   BIGINT,
  handled_at   TIMESTAMPTZ,
  created_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
  CONSTRAINT chk_support_requests_type
    CHECK (type IN ('ERROR','INQUIRY')),
  CONSTRAINT chk_support_requests_status
    CHECK (status IN ('OPEN','IN_PROGRESS','RESOLVED','WONTFIX'))
);

-- 관리자 목록 = status 필터 + 최신순 keyset. 정렬 키는 created_at 이 아니라 id 다
-- (BIGSERIAL 이라 단조 증가 = 시간 순서이고, keyset cursor 로 쓰려면 유일해야 한다).
CREATE INDEX idx_support_requests_status_id
  ON support_requests (status, id DESC);

-- 정규화 자식. 부모가 단일이라 ③과 달리 실제 FK 를 걸 수 있다.
CREATE TABLE support_request_failures (
  id          BIGSERIAL PRIMARY KEY,
  request_id  BIGINT       NOT NULL REFERENCES support_requests(id) ON DELETE CASCADE,
  seq         SMALLINT     NOT NULL,      -- 0 = 가장 최근, 최대 9
  method      VARCHAR(8)   NOT NULL,
  path        VARCHAR(512) NOT NULL,      -- 쿼리스트링 제거
  status_code SMALLINT,                   -- 네트워크 실패면 NULL
  error_code  VARCHAR(64),
  trace_id    VARCHAR(64),
  message     VARCHAR(500),               -- 마스킹된 응답 message
  occurred_at TIMESTAMPTZ  NOT NULL,
  CONSTRAINT uq_support_request_failures_seq UNIQUE (request_id, seq)
);

CREATE INDEX idx_support_request_failures_request
  ON support_request_failures (request_id, seq);

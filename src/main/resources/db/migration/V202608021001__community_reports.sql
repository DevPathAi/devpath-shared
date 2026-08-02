-- 커뮤니티 신고. 대상은 글·답변·댓글 3종이라 (target_type, target_id) 다형 참조를 쓴다.
-- 다형 참조라 FK 를 걸 수 없다 — 대상 삭제 시 신고는 남고, 조회 시 대상이 없으면
-- 애플리케이션이 "삭제된 콘텐츠"로 표시한다.
CREATE TABLE community_reports (
  id          BIGSERIAL PRIMARY KEY,
  reporter_id BIGINT      NOT NULL,
  target_type VARCHAR(16) NOT NULL,
  target_id   BIGINT      NOT NULL,
  category    VARCHAR(16) NOT NULL,
  reason      TEXT,
  status      VARCHAR(16) NOT NULL DEFAULT 'OPEN',
  reviewed_by BIGINT,
  reviewed_at TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_community_reports_target CHECK (target_type IN ('POST','ANSWER','COMMENT')),
  CONSTRAINT chk_community_reports_category CHECK (category IN ('SPAM','ABUSE','AD','DUPLICATE','INAPPROPRIATE','ETC')),
  CONSTRAINT chk_community_reports_status CHECK (status IN ('OPEN','RESOLVED','REJECTED')),
  -- 1인 1회. 이 제약이 있어야 "몇 명이 신고했는가"가 심각도 신호가 된다.
  CONSTRAINT uq_community_reports_once UNIQUE (reporter_id, target_type, target_id)
);

-- 관리자 목록 기본 질의: status 필터 + 최신순.
CREATE INDEX idx_community_reports_status_created
  ON community_reports (status, created_at DESC);

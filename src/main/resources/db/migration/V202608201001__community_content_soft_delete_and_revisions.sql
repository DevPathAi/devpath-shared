-- 답변·댓글에 소프트 삭제 상태를 더한다. community_posts 는 이미
-- chk_community_posts_status 로 DRAFT/PUBLISHED/HIDDEN/DELETED 를 갖고 있으므로
-- 어휘를 맞추되, 초안 개념이 없는 두 테이블에서는 DRAFT 를 뺀다.
--
-- 상태가 삭제 주체를 구분한다: DELETED=작성자가 지움(평판 유지) ·
-- HIDDEN=관리자가 내림(평판 회수). 그래서 "누가 지웠는가" 를 위한 별도 컬럼이 없다.
ALTER TABLE community_answers  ADD COLUMN status VARCHAR(16) NOT NULL DEFAULT 'PUBLISHED';
ALTER TABLE community_comments ADD COLUMN status VARCHAR(16) NOT NULL DEFAULT 'PUBLISHED';

-- NOT VALID 로 마이그레이션 락 아래 전체 스캔을 피한다(V202608161007 과 같은 방식).
-- 새 값은 즉시 거부되고, 기존 행 검증은 다음 마이그레이션이 맡는다.
ALTER TABLE community_answers  ADD CONSTRAINT chk_community_answers_status
  CHECK (status IN ('PUBLISHED','HIDDEN','DELETED')) NOT VALID;
ALTER TABLE community_comments ADD CONSTRAINT chk_community_comments_status
  CHECK (status IN ('PUBLISHED','HIDDEN','DELETED')) NOT VALID;

-- 수정 이력. community_reports 와 같은 다형 대상 패턴(target_type + target_id)이다.
-- 질문은 board_type='QNA' 인 게시글이므로 target_type 은 POST 다 —
-- ReportTargetType 과 같은 3값 어휘를 쓴다.
CREATE TABLE community_content_revisions (
  id          BIGSERIAL PRIMARY KEY,
  target_type VARCHAR(16) NOT NULL,
  target_id   BIGINT      NOT NULL,
  -- 글·질문만 제목이 있다(답변·댓글은 NULL). community_posts.title 과 같은 길이다.
  title       VARCHAR(120),
  body_md     TEXT        NOT NULL,
  body_html   TEXT,
  edited_by   BIGINT      NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_community_revisions_target CHECK (target_type IN ('POST','ANSWER','COMMENT'))
);
CREATE INDEX idx_community_revisions_target
  ON community_content_revisions(target_type, target_id, created_at DESC);

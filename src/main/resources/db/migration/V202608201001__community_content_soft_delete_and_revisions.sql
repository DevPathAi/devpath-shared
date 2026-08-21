-- 답변·댓글에 소프트 삭제 상태를 더한다. community_posts 는 이미
-- chk_community_posts_status 로 DRAFT/PUBLISHED/HIDDEN/DELETED 를 갖고 있으므로
-- 어휘를 맞추되, 초안 개념이 없는 두 테이블에서는 DRAFT 를 뺀다.
--
-- 상태가 삭제 주체를 구분한다: DELETED=작성자가 지움(평판 유지) ·
-- HIDDEN=관리자가 내림(평판 회수). 그래서 "누가 지웠는가" 를 위한 별도 컬럼이 없다.
--
-- ★스키마를 명시적으로 묶는다★ — 부분 스키마 검증(임시 스키마에 baseline 이후 마이그레이션만
-- 돌리는 테스트)에서 unqualified 이름은 search_path 를 타고 **다른 스키마의 테이블**로 흘러간다.
-- 실측: community_answers 가 임시 스키마에 없어 public 의 것을 건드렸고
-- "column status of relation community_answers already exists" 로 7건이 깨졌다.
-- V202608161009 와 같은 방식이다.
DO $migration$
DECLARE
  schema_name TEXT := current_schema();
  answer_table TEXT := format('%I.community_answers', current_schema());
  comment_table TEXT := format('%I.community_comments', current_schema());
BEGIN
  -- 둘 다 없으면 부분 스키마 검증(임시 스키마) — 건너뛴다. 둘 다 있으면 운영 — 실행한다.
  -- ★한쪽만 없는 비대칭은 드리프트다 — 조용히 건너뛰면 Flyway 가 성공으로 기록해 영영
  -- 재시도가 없으므로, 실패로 세워 사람이 보게 한다(fail-open 금지).★
  IF to_regclass(answer_table) IS NULL AND to_regclass(comment_table) IS NULL THEN
    RAISE NOTICE 'Skipping community content soft delete: %.community_answers/comments is absent',
      schema_name;
    RETURN;
  ELSIF to_regclass(answer_table) IS NULL OR to_regclass(comment_table) IS NULL THEN
    RAISE EXCEPTION 'asymmetric community tables in schema % (answers: %, comments: %)',
      schema_name, to_regclass(answer_table) IS NOT NULL, to_regclass(comment_table) IS NOT NULL;
  END IF;

  EXECUTE format(
    'ALTER TABLE %s ADD COLUMN status VARCHAR(16) NOT NULL DEFAULT ''PUBLISHED''', answer_table);
  EXECUTE format(
    'ALTER TABLE %s ADD COLUMN status VARCHAR(16) NOT NULL DEFAULT ''PUBLISHED''', comment_table);

  -- NOT VALID 로 마이그레이션 락 아래 전체 스캔을 피한다(V202608161007 과 같은 방식).
  -- 새 값은 즉시 거부되고, 기존 행 검증은 다음 마이그레이션이 맡는다.
  EXECUTE format(
    'ALTER TABLE %s ADD CONSTRAINT chk_community_answers_status '
      || 'CHECK (status IN (''PUBLISHED'',''HIDDEN'',''DELETED'')) NOT VALID', answer_table);
  EXECUTE format(
    'ALTER TABLE %s ADD CONSTRAINT chk_community_comments_status '
      || 'CHECK (status IN (''PUBLISHED'',''HIDDEN'',''DELETED'')) NOT VALID', comment_table);
END
$migration$;

-- 수정 이력. community_reports 와 같은 다형 대상 패턴(target_type + target_id)이다.
-- 질문은 board_type='QNA' 인 게시글이므로 target_type 은 POST 다 —
-- ReportTargetType 과 같은 3값 어휘를 쓴다.
--
-- 이쪽은 새 테이블이라 search_path 문제가 없다(현재 스키마에 만들어진다).
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

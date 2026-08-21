-- 앞 마이그레이션이 NOT VALID 로 남긴 제약의 기존 행 검증을 분리해 끝낸다.
--
-- 앞 마이그레이션과 같은 이유로 스키마를 명시적으로 묶는다 — 임시 스키마에서 건너뛴
-- 제약을 public 것으로 착각해 검증하면 안 된다.
DO $migration$
DECLARE
  schema_name TEXT := current_schema();
  answer_table TEXT := format('%I.community_answers', current_schema());
  comment_table TEXT := format('%I.community_comments', current_schema());
BEGIN
  -- 앞 마이그레이션과 같은 3분기: 둘 다 없음=스킵 / 비대칭=실패(fail-open 금지) / 둘 다 있음=실행.
  IF to_regclass(answer_table) IS NULL AND to_regclass(comment_table) IS NULL THEN
    RAISE NOTICE 'Skipping community content soft-delete validation: %.community_answers/comments is absent',
      schema_name;
    RETURN;
  ELSIF to_regclass(answer_table) IS NULL OR to_regclass(comment_table) IS NULL THEN
    RAISE EXCEPTION 'asymmetric community tables in schema % (answers: %, comments: %)',
      schema_name, to_regclass(answer_table) IS NOT NULL, to_regclass(comment_table) IS NOT NULL;
  END IF;

  EXECUTE format(
    'ALTER TABLE %s VALIDATE CONSTRAINT chk_community_answers_status', answer_table);
  EXECUTE format(
    'ALTER TABLE %s VALIDATE CONSTRAINT chk_community_comments_status', comment_table);
END
$migration$;

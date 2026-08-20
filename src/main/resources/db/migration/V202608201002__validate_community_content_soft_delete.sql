-- 앞 마이그레이션이 NOT VALID 로 남긴 제약의 기존 행 검증을 분리해 끝낸다.
ALTER TABLE community_answers  VALIDATE CONSTRAINT chk_community_answers_status;
ALTER TABLE community_comments VALIDATE CONSTRAINT chk_community_comments_status;

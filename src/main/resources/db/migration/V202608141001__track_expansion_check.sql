-- 트랙 3종 확장(PYTHON_BACKEND · NODE_TYPESCRIPT · DATA_AI)을 위해 track CHECK 를 넓힌다.
--
-- CHECK 는 값을 "허용"할 뿐이고 이용자에게 보이는 목록은 프론트 track_catalog.dart 가 정한다.
-- 그래서 세 값을 한 번에 열되, 실제 문항·콘텐츠는 트랙별로 따로 적재한다.
-- track 컬럼은 VARCHAR(20) 이라 세 값 모두 길이가 맞는다(14 · 15 · 7).

ALTER TABLE question_bank DROP CONSTRAINT chk_qb_track;
ALTER TABLE question_bank ADD CONSTRAINT chk_qb_track CHECK (
  track IN ('BACKEND_SPRING','FRONTEND_REACT','MOBILE_FLUTTER','DEVOPS','FULLSTACK',
            'PYTHON_BACKEND','NODE_TYPESCRIPT','DATA_AI'));

ALTER TABLE assessments DROP CONSTRAINT chk_assessments_track;
ALTER TABLE assessments ADD CONSTRAINT chk_assessments_track CHECK (
  track IN ('BACKEND_SPRING','FRONTEND_REACT','MOBILE_FLUTTER','DEVOPS','FULLSTACK',
            'PYTHON_BACKEND','NODE_TYPESCRIPT','DATA_AI'));

ALTER TABLE learning_paths DROP CONSTRAINT chk_lp_track;
ALTER TABLE learning_paths ADD CONSTRAINT chk_lp_track CHECK (
  track IN ('BACKEND_SPRING','FRONTEND_REACT','MOBILE_FLUTTER','DEVOPS','FULLSTACK',
            'PYTHON_BACKEND','NODE_TYPESCRIPT','DATA_AI'));

ALTER TABLE contents DROP CONSTRAINT chk_contents_track;
ALTER TABLE contents ADD CONSTRAINT chk_contents_track CHECK (
  track IN ('BACKEND_SPRING','FRONTEND_REACT','MOBILE_FLUTTER','DEVOPS','FULLSTACK',
            'PYTHON_BACKEND','NODE_TYPESCRIPT','DATA_AI'));

ALTER TABLE user_profiles DROP CONSTRAINT chk_target_track;
ALTER TABLE user_profiles ADD CONSTRAINT chk_target_track CHECK (
  target_track IS NULL OR target_track IN (
    'BACKEND_SPRING','FRONTEND_REACT','MOBILE_FLUTTER','DEVOPS','FULLSTACK',
    'PYTHON_BACKEND','NODE_TYPESCRIPT','DATA_AI'));

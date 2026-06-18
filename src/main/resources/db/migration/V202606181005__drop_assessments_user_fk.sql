-- 슬라이스 #2: assessments.user_id는 platform users로의 논리적 참조일 뿐 — 교차서비스 FK를 제거한다(서비스 경계).
-- learning-svc가 assessments를 소유하고 platform-svc가 users를 소유한다. 무결성은 애플리케이션/이벤트로 보장
-- (슬라이스 #1 경계 원칙: 교차 갱신은 이벤트로만). guest는 user_id NULL, 회원은 start/claim 시 결합.
ALTER TABLE assessments DROP CONSTRAINT IF EXISTS assessments_user_id_fkey;

-- 서비스 이용약관(v2) 최초 게시에 따른 재동의.
--
-- 그동안 동의 화면은 「서비스 이용약관 동의」를 필수로 받았지만 약관 문서 자체가
-- 없었다. 문서를 게시했으므로 기존 이용자에게 다시 동의를 받는다.
--
-- 라우터 게이트가 users.consent_status 만 보므로(프론트 router.dart) 이 값을
-- 되돌리는 것만으로 다음 접속 시 동의 화면으로 유도된다.
--
-- 기존 동의 이력(user_consents)은 삭제하지 않는다 — 언제 무엇에 동의했는지는
-- 법정 증빙이므로 보존한다.
UPDATE users
   SET consent_status = 'PENDING'
 WHERE consent_status = 'DONE'
   AND deleted_at IS NULL;

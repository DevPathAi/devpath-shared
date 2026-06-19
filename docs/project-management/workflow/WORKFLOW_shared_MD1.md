## Step 1: #1 OAuth/인증 — 스키마

> **상태(2026-06-19)**: 인증/사용자 스키마는 구현 완료. 진단 스키마는 slice2에서 추가 완료. 학습경로·콘텐츠·임베딩 스키마는 아직 미구현이다.

### 1.1 인증 도메인 Flyway
- [x] users·user_oauth_identities·user_profiles 스키마(W1 users 골격 확장)
- [x] outbox·notifications 스키마
- [x] question_bank·assessments·assessment_items·assessment_results 스키마
- [ ] learning_paths·contents·content_embeddings VECTOR(768) 스키마

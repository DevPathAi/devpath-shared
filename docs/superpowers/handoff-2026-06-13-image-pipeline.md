# 세션 핸드오프 — 이미지 빌드 파이프라인 (2026-06-13)

> **목적**: 이미지 파이프라인 세션을 다음 세션(**W2 OAuth2**)으로 이관한다.
> **원칙**: [절대 조건](https://github.com/DevPathAi/devpath-shared/blob/main/CLAUDE.md) — 추측 금지 / 테스트(검증) 우선 / 문제 시 코드 분석. 본 문서의 모든 상태는 실제 CI·커밋으로 검증됨.
> **선행**: [handoff-2026-06-13.md](handoff-2026-06-13.md)(W1 인프라)의 §5 "🔧 이미지 빌드 파이프라인" 미결을 본 세션이 해소.

---

## 1. 본 세션 완료 작업

| # | 작업 | 결과물 |
|---|------|--------|
| 1 | **documents/Home.md 색인 동기화** | W1 미결 정리 — 누락 24~34 + 사업 섹션 추가, 위키링크 37개 무결성 검증. PR 머지 |
| 2 | **컨테이너 이미지 빌드 파이프라인** | 아래 §2 (브레인스토밍→스펙→계획→subagent 구현→실검증) |
| 3 | **후속 정리** | 원격 feat 브랜치 10개 삭제 · plan/handoff 정합 · Node24 actions 버전 업 |

## 2. 이미지 파이프라인 — 완료·검증됨

**파이프라인**: 서비스 main 머지 → CI `image`(docker build → `ghcr.io/devpathai/<svc>:<sha>`+`:main` push) → `deploy`(GitHub App 토큰으로 devpath-gitops `kustomize edit set image` 봇 커밋·push) → ArgoCD가 gitops main 자동 sync.

- **검증**: 9개 서비스 main CI **image·deploy job 전부 green**, gitops에 `deploy(...)` **봇 커밋 9개** 생성 확인(실제 실행).
- **핵심 결정**: frontend **devpath-web/devpath-admin**(모노레포 web/admin, `nginx-unprivileged:1.27-alpine` 포트 8080), migration 전용 이미지(**Dockerfile.migration**, flyway:11-alpine), cross-repo는 **GitHub App**(PAT 아님), svc-template은 image job만.
- **Node24**: actions 버전 업(setup-gradle@v6·setup-node@v6·build-push@v7·login@v4·app-token@v3·setup-kubectl@v5) — 2026-06-16 deprecation 대비, image/deploy까지 green 검증.
- **스펙/계획**: `docs/superpowers/{specs,plans}/2026-06-13-image-pipeline*` · **메모리**: `image-pipeline`

## 3. 현재 상태 (검증됨)

- **전 레포 main 머지·CI green**. 원격 feat/image-pipeline·chore/node24 브랜치 정리됨(로컬 feat 잔존 가능 — 무해).
- **gitops main**: 9개 서비스(백엔드 6 + devpath-web + devpath-admin + _migration) image SHA 태그 관리, ApplicationSet `apps/*` 자동 발견.
- **GitHub App** `devpath-gitops-bot` 생성·org secret(`GITOPS_APP_ID`/`GITOPS_APP_PRIVATE_KEY`) 등록됨 — gitops contents:write.
- W1 노출 PAT는 폐기 완료(사용자 확인). 이제 gitops 쓰기는 GitHub App 단명 토큰.

## 4. 다음 단계 — W2 (OAuth2)

17_스케줄 Week 2: **Spring Security 7 + OAuth2 Client**(GitHub/Google/카카오 Provider), JWT + Refresh Cookie, `users`·`user_oauth_identities`·`user_profiles` 스키마 확장(W1 users 골격 위에), `UserRegisteredEvent` Outbox.

- **대상 레포**: `devpath-platform-svc`(user/auth) + `devpath-gateway`(OAuth2 엣지) + `devpath-shared`(이벤트·스키마)
- **권장 흐름**: 브레인스토밍 → 스펙 → 계획 → TDD (W1·이미지 파이프라인과 동일)
- ⚠️ **외부 의존성**: 카카오·Google OAuth 앱 심사 신청은 **소요가 길어** W2 코드(브레인스토밍·스펙·초기 TDD)와 **병행 신청** 필요. ※ 이건 로그인용 OAuth 앱으로, gitops용 GitHub App(`devpath-gitops-bot`)과는 별개.

## 5. 미결 / 주의사항

| 항목 | 내용 |
|------|------|
| ⚠️ **ci.yml paths 필터** | 서비스 `ci.yml`에 `paths` 필터가 없어 문서만 바뀐 main push에도 image/deploy가 실행됨(중복 배포 갱신 — 무해하나 비효율). 추후 `paths: ['src/**', ...]` 필터 검토 |
| ⚠️ **.omc 커밋 금지** | `.gitignore`에 `.omc/` 추가됨(shared·documents만). 나머지 8개 레포는 미추가 — **`git add -A` 금지**(명시적 파일만)로 회피. 여유 시 8개 레포 .gitignore에 `.omc/` 일괄 추가 권장 |
| 🔧 **ArgoCD 실 sync 미검증** | 클러스터(local-k8s/kind)가 없어 gitops 커밋·kustomize 렌더·ghcr 이미지까지만 검증. 클러스터 기동 시 ArgoCD Application sync/health 실검증 필요 |
| 📄 **로컬 feat 브랜치** | 원격 삭제됨, 일부 레포 로컬 `feat/image-pipeline` 잔존(정리 선택) |

## 6. 관련 메모리 (다음 세션 자동 로드)

- `image-pipeline` — 본 세션 결과·패턴
- `w1-infra-postgres` — W1 결정·Windows dev 우회
- `repo-structure-direction` · `no-guessing-test-first` · `synapse-troubleshooting-reference`

# 설계 — 컨테이너 이미지 빌드 파이프라인 (2026-06-13)

> **목표**: 서비스 소스 main 머지 시 컨테이너 이미지를 빌드해 `ghcr.io/devpathai`에 **커밋 SHA 불변 태그**로 push하고, devpath-gitops의 배포 매니페스트를 해당 SHA로 자동 갱신하여 ArgoCD가 배포하도록 한다.
> **원칙**: [절대 조건](https://github.com/DevPathAi/devpath-shared/blob/main/CLAUDE.md) — 추측 금지 / 검증 우선. 본 스펙의 "현재 상태"는 실제 파일로 검증됨.
> **W1 후속**: [handoff-2026-06-13](../handoff-2026-06-13.md) §5의 "🔧 이미지 빌드 파이프라인" 미결 항목.

---

## 1. 배경 / 현재 상태 (검증됨)

- 백엔드 7개 레포(svc-template 포함: gateway·platform·learning·community·ai·sandbox)는 **Dockerfile 존재**(`eclipse-temurin:21-jre-alpine` + `COPY build/libs/*-SNAPSHOT.jar`) + `ci.yml` 존재하나 **`./gradlew build`만 수행** — Docker 빌드·push 없음.
- gitops deployment image가 미완: platform-svc 등은 `ghcr.io/devpathai/`(이름·태그 비어 있음), frontend는 `ghcr.io/devpathai/devpath-frontend:latest`(가변 태그).
- gitops `kustomization.yaml`은 `resources: [deployment, service]`만 — **`images:` 블록 없음**.
- ArgoCD ApplicationSet이 `apps/*`를 자동 발견, `syncPolicy.automated`(prune+selfHeal)로 gitops `main`을 추적. **Image Updater 미설치**.
- frontend: gitops에 **web SPA용 deployment 하나만**(nginx, port 80). `web`·`admin`은 Vite+TS, `mobile`은 Flutter. **admin·mobile은 배포 deployment 없음**.
- 선행 프로젝트 Synapse 교훈: **이미지 태그 비결정성 → SHA 불변 태그**.

## 2. 결정사항 (사용자 승인)

| # | 결정 | 선택 |
|---|------|------|
| D1 | 범위 | 백엔드 6개 + frontend(web + admin) + migration 전용 이미지 |
| D2 | gitops 갱신 방식 | **CI가 gitops에 SHA 커밋** (kustomize edit set image → commit·push). Image Updater 미도입 |
| D3 | migration SQL 주입 | **전용 migration 이미지**(shared가 db/migration을 구운 Flyway 이미지 빌드) |
| D4 | cross-repo 쓰기 권한 | **GitHub App**(gitops `contents:write` fine-grained, `actions/create-github-app-token`으로 단명 토큰) |
| D5 | 태그 | 불변 `:<github.sha>`(배포 참조), 이동 `:main`(디버깅용 병행) |
| D6 | 트리거 | main push 시 빌드·push·배포. PR은 기존 `build` 검증만 |

## 3. 아키텍처

```
[서비스 레포 main push]
  └ CI job: build      → ./gradlew build            (기존, 테스트 포함)
  └ CI job: image      → docker build (기존 Dockerfile)
                       → ghcr.io/devpathai/<svc>:<sha> + :main  push
  └ CI job: deploy     → GitHub App 토큰 발급
                       → gitops checkout
                       → kustomize edit set image <svc>=ghcr.io/devpathai/<svc>:<sha>  (apps/<svc>/base)
                       → git commit && push (pull --rebase 재시도)
  └ ArgoCD             → gitops main 변경 감지 → 자동 sync → 배포
```

`image`·`deploy`는 `build` 성공 + `github.ref == refs/heads/main`일 때만 실행(`needs: build`, `if:`).

## 4. 컴포넌트별 설계

### 4.1 백엔드 6개 서비스 + svc-template
- 기존 Dockerfile 그대로 사용(빌드된 jar 복사). 변경 없음.
- `ci.yml`에 job 추가:
  - `image` job: `permissions: packages: write`, `docker/login-action`(`${{ github.actor }}` / `GITHUB_TOKEN`) → `docker/build-push-action`(`tags: ghcr.io/devpathai/<svc>:${{ github.sha }}, ghcr.io/devpathai/<svc>:main`). ghcr push는 동일 org라 `GITHUB_TOKEN`으로 충분.
  - `deploy` job: GitHub App 토큰으로 gitops 갱신(§4.2).
- **svc-template에 동일 반영** → 신규 서비스가 복제 시 자동 상속.

### 4.2 gitops 갱신
- deployment.yaml의 `image:`를 안정 기준값 `ghcr.io/devpathai/devpath-<svc>:main`으로 정리(현재 빈 `ghcr.io/devpathai/` 대체).
- 각 `apps/<svc>/base/kustomization.yaml`에 `images:` 블록 신설(`name`이 deployment image와 매칭되어 태그를 덮어씀):
  ```yaml
  images:
    - name: ghcr.io/devpathai/devpath-<svc>   # deployment image와 매칭
      newTag: main                            # CI가 <sha>로 갱신
  ```
- `deploy` job 절차: `create-github-app-token` → gitops checkout → `kustomize edit set image ghcr.io/devpathai/devpath-<svc>=ghcr.io/devpathai/devpath-<svc>:${{ github.sha }}` (apps/<svc>/base) → `git commit -m "deploy(<svc>): <sha>"` → `git push`(실패 시 `git pull --rebase` 후 재시도, 동시 push 충돌 대비).
- **GitHub App**: org `DevPathAi`에 App 생성, `contents: write`(gitops 레포 한정), 서비스 레포에 설치. `APP_ID`·`APP_PRIVATE_KEY`는 org/레포 secret.

### 4.3 frontend (web + admin)
- devpath-frontend는 모노레포(`web`·`admin`=Vite+TS, `mobile`=Flutter). **신규** `ci.yml` 하나에서 web·admin을 **matrix**로 처리.
- 각 앱(web·admin): **신규** multi-stage Dockerfile(`node:lts`에서 `npm ci && npm run build` → `nginx:alpine`에 `dist/` 복사 + SPA fallback `nginx.conf`, port 80).
- CI(앱별): `npm ci`(`<app>/`) → `npm run build` → docker build → ghcr push(`:<sha>`,`:main`) → gitops set image.
  - 이미지명: web=`ghcr.io/devpathai/devpath-frontend`, admin=`ghcr.io/devpathai/devpath-frontend-admin`.
- **web**: 기존 `apps/devpath-frontend` deployment의 `:latest`를 kustomize `images:` SHA 참조로 정리.
- **admin**: gitops에 deployment 부재 → **`apps/devpath-frontend-admin/base/`(deployment+service+kustomization) 신설**(web과 동일 구조: nginx, port 80). ApplicationSet이 자동 발견·배포.
- **mobile(Flutter) 제외**(앱스토어 배포 경로).

### 4.4 migration 전용 이미지
- devpath-shared에 **신규** `Dockerfile.migration`(또는 `migration/Dockerfile`): `FROM flyway/flyway:11-alpine` + `COPY src/main/resources/db/migration /flyway/sql`.
- shared `ci.yml`: 기존 build·publish(GitHub Packages)에 더해 이미지 빌드 → `ghcr.io/devpathai/devpath-migration:<sha>`,`:main` push → gitops `apps/_migration` set image.
- gitops `_migration/job.yaml`: `image`를 SHA 참조로, `-locations=filesystem:/flyway/sql` 유지, **SQL 마운트 TODO 주석 제거**(이미지에 포함). `_migration/kustomization.yaml`에 `images:` 블록 신설.

## 5. 검증 전략 (절대원칙: 검증 우선)

CI/CD는 단위테스트가 어려우므로 **실제 실행 관찰**로 검증한다.

| 대상 | 검증 |
|------|------|
| 백엔드 이미지 | `docker build` 성공 → `docker run` → `GET /actuator/health` = `UP` |
| frontend 이미지(web·admin) | 각 이미지 `docker build`/`run` → `GET /` = 200, SPA 라우트 fallback 동작 |
| migration 이미지 | `docker run ... info` 로 Flyway가 `/flyway/sql` 마이그레이션 인식 확인 |
| gitops | `kubectl kustomize apps/<svc>/base`가 **새 SHA image**로 렌더 |
| 전 과정 | 실제 main push로 build→push→gitops 커밋→ArgoCD sync 그린 확인(W1과 동일, 추측 아닌 실제) |

## 6. 구현 순서 (writing-plans가 상세화)

1. **GitHub App 생성·secret 등록** (org admin = 사용자 작업, 외부 선행).
2. **PoC(platform-svc 1개)**: image+deploy job + kustomization images 블록 → §5로 검증.
3. 검증 통과 시 **나머지 5개 서비스 + svc-template** 전파(동일 패턴).
4. **frontend(web + admin)** Dockerfile+CI 신규. admin은 `apps/devpath-frontend-admin/base/` deployment 신설 동반.
5. **migration 전용 이미지**(shared) + gitops `_migration` 연동.
6. **전체 통합 검증** — 각 레포 실제 push로 그린·배포 렌더 확인.

## 7. 미결 / 리스크

- **GitHub App 생성은 사용자(org admin) 선행 작업** — 없으면 deploy job 동작 불가.
- ghcr org packages **가시성**(public/private) + 서비스 레포 pull 권한 설정 필요.
- 동시 다중 push 시 gitops 충돌 → `pull --rebase` 재시도로 완화(드물면 충분, 잦으면 별도 배포 브랜치 큐 검토).
- W1 노출 PAT는 폐기 완료(handoff §5) — 본 파이프라인은 PAT 대신 GitHub App 사용.

## 8. 범위 밖 (YAGNI)

- mobile(Flutter) 이미지화(앱스토어 경로).
- ArgoCD Image Updater 도입.
- 멀티 아키텍처(arm64) 빌드, 이미지 서명(cosign), SBOM.
- 환경별(staging/prod) overlay — 현재 base만 존재.

# 컨테이너 이미지 빌드 파이프라인 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 서비스 main 머지 시 컨테이너 이미지를 빌드해 `ghcr.io/devpathai`에 커밋 SHA 불변 태그로 push하고, CI가 devpath-gitops의 image 태그를 갱신해 ArgoCD가 자동 배포한다.

**Architecture:** 각 서비스 GitHub Actions에 `image`(docker build+push)·`deploy`(GitHub App 토큰으로 gitops `kustomize edit set image` 커밋) job을 추가한다. gitops `kustomization.yaml`의 `images:` 블록이 단일 갱신 지점이다. frontend(web/admin)·migration(전용 Flyway 이미지)은 동일 패턴을 변형 적용한다.

**Tech Stack:** GitHub Actions, `docker/build-push-action`, `actions/create-github-app-token`, Kustomize, ArgoCD, Spring Boot 4(Gradle), Vite, Flyway.

**Spec:** `docs/superpowers/specs/2026-06-13-image-pipeline-design.md`

**검증 철학:** 이 작업은 단위테스트가 부적합하다. 절대원칙의 "테스트 우선"은 **실제 실행 관찰**(docker build/run, `kubectl kustomize` 렌더, 실제 CI green)로 적용한다. 각 Task는 "베이스라인 확인 → 작성 → 실행 검증 → 커밋" 순서다.

**전제:** 모든 작업 디렉토리는 `D:\workspace\dev-path-ai\<repo>`. 각 레포는 독립 git 레포(main 브랜치, clean). 커밋·푸시는 **사용자가 명시 요청할 때만** 수행한다(절대원칙). 아래 커밋 step은 사용자 승인 후 일괄 실행 가능.

---

## Task 0: GitHub App 생성 (사용자 선행 작업 — 외부)

deploy job의 전제. **org admin(사용자)만 수행 가능**하므로 코드가 아닌 안내다.

- [ ] **Step 1: GitHub App 생성**
  - GitHub → DevPathAi org → Settings → Developer settings → GitHub Apps → New GitHub App
  - 이름 예: `devpath-gitops-bot`
  - Repository permissions: **Contents: Read and write** (그 외 모두 No access)
  - "Where can this app be installed": Only this account
  - Webhook: 비활성(Active 체크 해제)

- [ ] **Step 2: App 설치 + 키 발급**
  - 생성 후 **Install App** → DevPathAi → repositories: 최소 `devpath-gitops` 포함(전 서비스 레포에서 토큰 발급하므로 All repositories 권장)
  - **App ID** 기록, **Generate a private key**로 `.pem` 다운로드

- [ ] **Step 3: org secret 등록**
  - DevPathAi org → Settings → Secrets and variables → Actions → New organization secret
  - `GITOPS_APP_ID` = App ID
  - `GITOPS_APP_PRIVATE_KEY` = `.pem` 파일 전체 내용
  - 가시성: 전 레포 또는 대상 레포 한정

- [ ] **Step 4: 확인**
  - org secret 목록에 `GITOPS_APP_ID`·`GITOPS_APP_PRIVATE_KEY` 존재 확인
  - 이 두 secret 없이는 Task 1의 deploy job이 실패한다. 진행 전 반드시 완료.

---

## Task 1: platform-svc PoC (백엔드 1개로 전체 흐름 검증)

먼저 1개 서비스로 build→push→gitops 갱신 전 과정을 검증한다. 통과하면 Task 2에서 나머지에 전파한다.

**Files:**
- Modify: `devpath-platform-svc/.github/workflows/ci.yml`
- Modify: `devpath-gitops/apps/devpath-platform-svc/base/deployment.yaml:20`
- Modify: `devpath-gitops/apps/devpath-platform-svc/base/kustomization.yaml`
- 확인(변경 없음): `devpath-platform-svc/Dockerfile`

- [ ] **Step 1: 베이스라인 — Dockerfile 빌드가 되는지 로컬 확인**

Run:
```
cd D:\workspace\dev-path-ai\devpath-platform-svc
./gradlew bootJar
docker build -t devpath-platform-svc:local .
```
Expected: `docker build` 성공(이미지 생성). 기존 Dockerfile(`temurin:21-jre-alpine` + jar 복사)이 유효함을 확인. 실패 시 jar 경로(`build/libs/*-SNAPSHOT.jar`) 확인.

- [ ] **Step 2: ci.yml에 `image` job 추가**

`devpath-platform-svc/.github/workflows/ci.yml`의 기존 `build` job은 그대로 두고, `jobs:` 아래(같은 들여쓰기)에 추가:

```yaml
  image:
    needs: build
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-java@v5
        with:
          distribution: temurin
          java-version: 21
      - uses: gradle/actions/setup-gradle@v4
      - run: ./gradlew bootJar
        env:
          GITHUB_ACTOR: ${{ github.actor }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: |
            ghcr.io/devpathai/devpath-platform-svc:${{ github.sha }}
            ghcr.io/devpathai/devpath-platform-svc:main
```

- [ ] **Step 3: ci.yml에 `deploy` job 추가 (gitops 갱신)**

같은 `jobs:` 아래에 추가:

```yaml
  deploy:
    needs: image
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/create-github-app-token@v1
        id: app-token
        with:
          app-id: ${{ secrets.GITOPS_APP_ID }}
          private-key: ${{ secrets.GITOPS_APP_PRIVATE_KEY }}
          owner: DevPathAi
          repositories: devpath-gitops
      - uses: actions/checkout@v6
        with:
          repository: DevPathAi/devpath-gitops
          token: ${{ steps.app-token.outputs.token }}
          path: gitops
      - name: Install kustomize
        run: |
          curl -sLo kustomize.tar.gz https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.4.3/kustomize_v5.4.3_linux_amd64.tar.gz
          tar -xzf kustomize.tar.gz && sudo mv kustomize /usr/local/bin/
      - name: set image to commit SHA
        working-directory: gitops/apps/devpath-platform-svc/base
        run: kustomize edit set image ghcr.io/devpathai/devpath-platform-svc=ghcr.io/devpathai/devpath-platform-svc:${{ github.sha }}
      - name: commit & push
        working-directory: gitops
        run: |
          git config user.name "devpath-gitops-bot[bot]"
          git config user.email "devpath-gitops-bot[bot]@users.noreply.github.com"
          git add -A
          git diff --cached --quiet && echo "no change" && exit 0
          git commit -m "deploy(platform-svc): ${{ github.sha }}"
          for i in 1 2 3; do git push && break || (git pull --rebase && sleep 2); done
```

- [ ] **Step 4: gitops deployment.yaml image 정리**

`devpath-gitops/apps/devpath-platform-svc/base/deployment.yaml` 20번째 줄:
```yaml
          image: ghcr.io/devpathai/
```
를 다음으로 교체(주석 줄은 유지):
```yaml
          image: ghcr.io/devpathai/devpath-platform-svc:main
```

- [ ] **Step 5: gitops kustomization.yaml에 images 블록 추가**

`devpath-gitops/apps/devpath-platform-svc/base/kustomization.yaml`을 다음으로 교체:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
images:
  - name: ghcr.io/devpathai/devpath-platform-svc
    newTag: main
```

- [ ] **Step 6: gitops 렌더 검증 (로컬)**

Run:
```
cd D:\workspace\dev-path-ai\devpath-gitops
kubectl kustomize apps/devpath-platform-svc/base
```
Expected: 출력 Deployment의 `image:`가 `ghcr.io/devpathai/devpath-platform-svc:main`으로 렌더. (kustomize 미설치 시 `kubectl kustomize` 또는 위 Step 3 방식으로 설치)

- [ ] **Step 7: 커밋 (사용자 승인 후)**

```bash
# devpath-platform-svc
cd D:\workspace\dev-path-ai\devpath-platform-svc
git add .github/workflows/ci.yml
git commit -m "ci: 이미지 빌드·push + gitops 배포 job 추가"

# devpath-gitops
cd D:\workspace\dev-path-ai\devpath-gitops
git add apps/devpath-platform-svc/base/
git commit -m "feat(platform-svc): image kustomize 태그 관리 + deployment image 확정"
```

- [ ] **Step 8: 실제 CI 검증 (push 후 — 절대원칙: 실제 실행 확인)**

push 후 GitHub Actions에서 확인:
- `build` → `image` → `deploy` job 순서로 모두 green
- ghcr.io/devpathai에 `devpath-platform-svc:<sha>` 패키지 생성됨
- devpath-gitops에 `deploy(platform-svc): <sha>` 커밋 생성됨
- (클러스터 있으면) ArgoCD가 해당 SHA로 sync

Expected: 위 4가지 모두 확인. **하나라도 실패하면 로그를 읽고 원인 규명 후 수정**(추측 금지). Task 2 진행 전 PoC가 green이어야 한다.

---

## Task 2: 나머지 5개 백엔드 서비스 + svc-template 전파

Task 1에서 검증된 패턴을 동일 적용한다. 차이는 **레포명/이미지명/디렉토리명(`<svc>`)뿐**이다.

**대상 `<svc>` (레포명 = 이미지명):**
`devpath-gateway`, `devpath-learning-svc`, `devpath-community-svc`, `devpath-ai-svc`, `devpath-sandbox-svc`, **`devpath-svc-template`**(템플릿 — 신규 서비스 자동 상속).

- [ ] **Step 1: 각 레포 Dockerfile 동일성 확인**

Run:
```
cd D:\workspace\dev-path-ai
for s in devpath-gateway devpath-learning-svc devpath-community-svc devpath-ai-svc devpath-sandbox-svc devpath-svc-template; do echo "== $s =="; cat $s/Dockerfile; done
```
Expected: 모두 platform-svc와 동일한 `temurin:21-jre-alpine` + `COPY build/libs/*-SNAPSHOT.jar` 패턴. 다르면 해당 레포 step에서 조정.

- [ ] **Step 2: 각 레포 ci.yml에 image + deploy job 추가**

각 `<svc>`의 `.github/workflows/ci.yml`에 Task 1 Step 2·3의 job을 추가하되, **`devpath-platform-svc` 문자열을 `<svc>`로 모두 치환**한다(이미지 태그 2곳, set image 1곳, working-directory 경로 1곳, 커밋 메시지). `image`/`deploy` job 구조·`needs`·`if`·GitHub App step은 동일.

> svc-template 주의: 템플릿이므로 `<svc>`를 **그대로 `devpath-svc-template`**로 둔다. 복제 스크립트가 settings/build.gradle/패키지와 함께 ci.yml의 이미지명도 치환하도록, 복제 가이드(repo-structure-direction)의 치환 목록에 "ci.yml 이미지명"을 추가한다.

- [ ] **Step 3: 각 레포 대응 gitops 디렉토리 정리**

각 `<svc>`(svc-template 제외 — gitops에 배포 대상 없음)에 대해 Task 1 Step 4·5를 적용:
- `devpath-gitops/apps/<svc>/base/deployment.yaml`의 `image: ghcr.io/devpathai/` → `image: ghcr.io/devpathai/<svc>:main`
- `devpath-gitops/apps/<svc>/base/kustomization.yaml`에 images 블록 추가(name=`ghcr.io/devpathai/<svc>`, newTag=`main`)

대상: `devpath-gateway`, `devpath-learning-svc`, `devpath-community-svc`, `devpath-ai-svc`, `devpath-sandbox-svc` (5개).

- [ ] **Step 4: 렌더 검증 (5개 일괄)**

Run:
```
cd D:\workspace\dev-path-ai\devpath-gitops
for s in devpath-gateway devpath-learning-svc devpath-community-svc devpath-ai-svc devpath-sandbox-svc; do echo "== $s =="; kubectl kustomize apps/$s/base | grep "image:"; done
```
Expected: 각 출력이 `image: ghcr.io/devpathai/<svc>:main`.

- [ ] **Step 5: 커밋 (사용자 승인 후)**

각 서비스 레포에서 `git add .github/workflows/ci.yml && git commit -m "ci: 이미지 빌드·push + gitops 배포 job 추가"`. svc-template도 동일. gitops는 5개 디렉토리 묶어 `git commit -m "feat: 5개 서비스 image kustomize 태그 관리"`.

- [ ] **Step 6: 실제 CI 검증**

각 서비스 push 후 build→image→deploy green, ghcr 패키지 생성, gitops 커밋 확인(Task 1 Step 8 기준). svc-template은 gitops 배포 대상이 없으므로 deploy job이 "no change"로 정상 종료되는지 확인(또는 템플릿은 image job까지만 두는 판단 — 이 경우 deploy job 제거).

> **결정 포인트(실행 중 확인):** svc-template은 배포 대상 gitops 디렉토리가 없다. ⓐ deploy job 포함(복제 후 활성) vs ⓑ 템플릿은 image job까지만. 권장 ⓐ(복제 시 그대로 동작). 실행자가 사용자에게 확인.

---

## Task 3: frontend web + admin 이미지

devpath-frontend 모노레포. web·admin은 Vite+TS(동일), mobile(Flutter) 제외. 한 ci.yml에서 matrix로 처리.

**Files:**
- Create: `devpath-frontend/web/Dockerfile`, `devpath-frontend/web/nginx.conf`
- Create: `devpath-frontend/admin/Dockerfile`, `devpath-frontend/admin/nginx.conf`
- Create: `devpath-frontend/.github/workflows/ci.yml`
- Modify: `devpath-gitops/apps/devpath-frontend/base/deployment.yaml:20`, `.../kustomization.yaml`

- [ ] **Step 1: web/admin Dockerfile 생성 (동일 내용, 각 디렉토리)**

`devpath-frontend/web/Dockerfile` 및 `devpath-frontend/admin/Dockerfile` (내용 동일):
```dockerfile
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:1.27-alpine AS runtime
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
```

- [ ] **Step 2: web/admin nginx.conf 생성 (SPA fallback, 동일 내용)**

`devpath-frontend/web/nginx.conf` 및 `devpath-frontend/admin/nginx.conf`:
```nginx
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

- [ ] **Step 3: 베이스라인 — 로컬 빌드 확인**

Run (web, admin 각각):
```
cd D:\workspace\dev-path-ai\devpath-frontend\web
npm ci
npm run build
docker build -t devpath-frontend:local .
docker run -d -p 8081:80 --name fe-test devpath-frontend:local
curl -s -o /dev/null -w "%{http_code}" http://localhost:8081/
docker rm -f fe-test
```
Expected: `npm run build`가 `dist/` 생성, `docker build` 성공, `curl`이 `200`. admin은 포트 8082로 동일 확인.

- [ ] **Step 4: ci.yml 생성 (matrix web/admin)**

`devpath-frontend/.github/workflows/ci.yml`:
```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:

jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        app: [web, admin]
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-node@v4
        with:
          node-version: 22
      - run: npm ci
        working-directory: ${{ matrix.app }}
      - run: npm run build
        working-directory: ${{ matrix.app }}

  image:
    needs: build
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    strategy:
      matrix:
        include:
          - app: web
            imageName: devpath-frontend
          - app: admin
            imageName: devpath-frontend-admin
    steps:
      - uses: actions/checkout@v6
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/build-push-action@v6
        with:
          context: ${{ matrix.app }}
          push: true
          tags: |
            ghcr.io/devpathai/${{ matrix.imageName }}:${{ github.sha }}
            ghcr.io/devpathai/${{ matrix.imageName }}:main

  deploy:
    needs: image
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    strategy:
      matrix:
        include:
          - imageName: devpath-frontend
            appDir: devpath-frontend
          - imageName: devpath-frontend-admin
            appDir: devpath-frontend-admin
    steps:
      - uses: actions/create-github-app-token@v1
        id: app-token
        with:
          app-id: ${{ secrets.GITOPS_APP_ID }}
          private-key: ${{ secrets.GITOPS_APP_PRIVATE_KEY }}
          owner: DevPathAi
          repositories: devpath-gitops
      - uses: actions/checkout@v6
        with:
          repository: DevPathAi/devpath-gitops
          token: ${{ steps.app-token.outputs.token }}
          path: gitops
      - name: Install kustomize
        run: |
          curl -sLo kustomize.tar.gz https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.4.3/kustomize_v5.4.3_linux_amd64.tar.gz
          tar -xzf kustomize.tar.gz && sudo mv kustomize /usr/local/bin/
      - name: set image
        working-directory: gitops/apps/${{ matrix.appDir }}/base
        run: kustomize edit set image ghcr.io/devpathai/${{ matrix.imageName }}=ghcr.io/devpathai/${{ matrix.imageName }}:${{ github.sha }}
      - name: commit & push
        working-directory: gitops
        run: |
          git config user.name "devpath-gitops-bot[bot]"
          git config user.email "devpath-gitops-bot[bot]@users.noreply.github.com"
          git add -A
          git diff --cached --quiet && echo "no change" && exit 0
          git commit -m "deploy(${{ matrix.imageName }}): ${{ github.sha }}"
          for i in 1 2 3; do git push && break || (git pull --rebase && sleep 2); done
```

> admin deploy는 Task 4에서 만드는 `apps/devpath-frontend-admin`이 있어야 동작한다. Task 4를 Task 3 커밋 전에 완료하거나, admin deploy를 Task 4 이후 활성화한다.

- [ ] **Step 5: web gitops 정리**

`devpath-gitops/apps/devpath-frontend/base/deployment.yaml` 20번째 줄 `image: ghcr.io/devpathai/devpath-frontend:latest` → `image: ghcr.io/devpathai/devpath-frontend:main`.
`.../kustomization.yaml`에 images 블록 추가:
```yaml
images:
  - name: ghcr.io/devpathai/devpath-frontend
    newTag: main
```

- [ ] **Step 6: 커밋 (사용자 승인 후 — Task 4 완료 후 일괄 권장)**

```bash
cd D:\workspace\dev-path-ai\devpath-frontend
git add web/Dockerfile web/nginx.conf admin/Dockerfile admin/nginx.conf .github/workflows/ci.yml
git commit -m "ci: web·admin nginx 이미지 빌드·push + gitops 배포 job 추가"
```

---

## Task 4: admin gitops deployment 신설

admin은 gitops에 배포 대상이 없다. web과 동일 구조로 신설한다. ApplicationSet이 `apps/*`를 자동 발견하므로 디렉토리만 추가하면 된다.

**Files:**
- Create: `devpath-gitops/apps/devpath-frontend-admin/base/deployment.yaml`
- Create: `devpath-gitops/apps/devpath-frontend-admin/base/service.yaml`
- Create: `devpath-gitops/apps/devpath-frontend-admin/base/kustomization.yaml`

- [ ] **Step 1: deployment.yaml 생성**

`devpath-gitops/apps/devpath-frontend-admin/base/deployment.yaml` (web deployment를 admin으로 치환):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: devpath-frontend-admin
  labels:
    app: devpath-frontend-admin
spec:
  replicas: 1
  selector:
    matchLabels:
      app: devpath-frontend-admin
  template:
    metadata:
      labels:
        app: devpath-frontend-admin
    spec:
      containers:
        - name: devpath-frontend-admin
          # admin SPA를 nginx로 서빙한다. 이미지 태그는 CI가 교체.
          image: ghcr.io/devpathai/devpath-frontend-admin:main
          ports:
            - containerPort: 80
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
          livenessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 10
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              memory: 128Mi
```

- [ ] **Step 2: service.yaml 생성**

먼저 web service.yaml을 참고로 동일 구조 생성:
Run: `cat D:\workspace\dev-path-ai\devpath-gitops\apps\devpath-frontend\base\service.yaml`
그 내용에서 `devpath-frontend` → `devpath-frontend-admin`으로 치환해 `devpath-gitops/apps/devpath-frontend-admin/base/service.yaml` 생성(포트/셀렉터 동일 구조 유지).

- [ ] **Step 3: kustomization.yaml 생성**

`devpath-gitops/apps/devpath-frontend-admin/base/kustomization.yaml`:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
images:
  - name: ghcr.io/devpathai/devpath-frontend-admin
    newTag: main
```

- [ ] **Step 4: 렌더 검증**

Run:
```
cd D:\workspace\dev-path-ai\devpath-gitops
kubectl kustomize apps/devpath-frontend-admin/base
```
Expected: Deployment+Service 렌더, image가 `ghcr.io/devpathai/devpath-frontend-admin:main`.

- [ ] **Step 5: 커밋 (사용자 승인 후 — Task 3 frontend 커밋과 함께)**

```bash
cd D:\workspace\dev-path-ai\devpath-gitops
git add apps/devpath-frontend/base/ apps/devpath-frontend-admin/base/
git commit -m "feat(frontend): web image 태그 관리 + admin deployment 신설"
```

- [ ] **Step 6: 실제 CI 검증**

devpath-frontend push 후 build(web,admin)→image(web,admin)→deploy(web,admin) green. ghcr에 `devpath-frontend:<sha>`·`devpath-frontend-admin:<sha>` 생성. gitops에 두 deploy 커밋. ArgoCD가 `devpath-frontend-admin` Application 자동 발견.

---

## Task 5: migration 전용 Flyway 이미지

devpath-shared가 `db/migration` SQL을 구운 Flyway 이미지를 빌드한다. `_migration` Job이 이 이미지를 쓴다.

**Files:**
- Create: `devpath-shared/Dockerfile.migration`
- Modify: `devpath-shared/.github/workflows/publish.yml`
- Modify: `devpath-gitops/apps/_migration/base/job.yaml`, `.../kustomization.yaml`

- [ ] **Step 1: Dockerfile.migration 생성**

`devpath-shared/Dockerfile.migration`:
```dockerfile
FROM flyway/flyway:11-alpine
COPY src/main/resources/db/migration /flyway/sql
```

- [ ] **Step 2: 베이스라인 — 로컬 빌드 + SQL 인식 확인**

Run:
```
cd D:\workspace\dev-path-ai\devpath-shared
docker build -f Dockerfile.migration -t devpath-migration:local .
docker run --rm devpath-migration:local info -url=jdbc:postgresql://host.docker.internal:5432/devpath -user=devpath -password=localdev
```
Expected: `docker build` 성공. `info`가 `/flyway/sql`의 마이그레이션 3건(V202606150900/0901/0902)을 나열(DB 연결되면 상태까지, 미연결이어도 SQL 탐지 로그 확인).

- [ ] **Step 3: publish.yml에 migration-image job 추가**

`devpath-shared/.github/workflows/publish.yml`의 `jobs:` 아래에 추가:
```yaml
  migration-image:
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v6
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/build-push-action@v6
        with:
          context: .
          file: Dockerfile.migration
          push: true
          tags: |
            ghcr.io/devpathai/devpath-migration:${{ github.sha }}
            ghcr.io/devpathai/devpath-migration:main
      - uses: actions/create-github-app-token@v1
        id: app-token
        with:
          app-id: ${{ secrets.GITOPS_APP_ID }}
          private-key: ${{ secrets.GITOPS_APP_PRIVATE_KEY }}
          owner: DevPathAi
          repositories: devpath-gitops
      - uses: actions/checkout@v6
        with:
          repository: DevPathAi/devpath-gitops
          token: ${{ steps.app-token.outputs.token }}
          path: gitops
      - name: Install kustomize
        run: |
          curl -sLo kustomize.tar.gz https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.4.3/kustomize_v5.4.3_linux_amd64.tar.gz
          tar -xzf kustomize.tar.gz && sudo mv kustomize /usr/local/bin/
      - name: set image
        working-directory: gitops/apps/_migration/base
        run: kustomize edit set image ghcr.io/devpathai/devpath-migration=ghcr.io/devpathai/devpath-migration:${{ github.sha }}
      - name: commit & push
        working-directory: gitops
        run: |
          git config user.name "devpath-gitops-bot[bot]"
          git config user.email "devpath-gitops-bot[bot]@users.noreply.github.com"
          git add -A
          git diff --cached --quiet && echo "no change" && exit 0
          git commit -m "deploy(migration): ${{ github.sha }}"
          for i in 1 2 3; do git push && break || (git pull --rebase && sleep 2); done
```

- [ ] **Step 4: gitops _migration job.yaml 갱신**

`devpath-gitops/apps/_migration/base/job.yaml`의 `image: flyway/flyway:11-alpine`을 `image: ghcr.io/devpathai/devpath-migration:main`으로 교체. SQL 마운트 관련 주석(`# 마이그레이션 SQL(/flyway/sql)은 ...`) 2줄 제거(이미지에 포함되므로). `args`의 `-locations=filesystem:/flyway/sql`는 유지.

- [ ] **Step 5: _migration kustomization.yaml에 images 블록 추가**

`devpath-gitops/apps/_migration/base/kustomization.yaml`에 추가:
```yaml
images:
  - name: ghcr.io/devpathai/devpath-migration
    newTag: main
```

- [ ] **Step 6: 렌더 검증**

Run: `cd D:\workspace\dev-path-ai\devpath-gitops && kubectl kustomize apps/_migration/base`
Expected: Job의 `image`가 `ghcr.io/devpathai/devpath-migration:main`, args에 `-locations=filesystem:/flyway/sql` 유지.

- [ ] **Step 7: 커밋 (사용자 승인 후)**

```bash
cd D:\workspace\dev-path-ai\devpath-shared
git add Dockerfile.migration .github/workflows/publish.yml
git commit -m "ci: 마이그레이션 전용 Flyway 이미지 빌드·push + gitops 연동"
cd D:\workspace\dev-path-ai\devpath-gitops
git add apps/_migration/base/
git commit -m "feat(_migration): 전용 migration 이미지 참조 + kustomize 태그 관리"
```

- [ ] **Step 8: 실제 CI 검증**

shared의 `src/**` 변경 push 시 publish + migration-image green. ghcr에 `devpath-migration:<sha>` 생성, gitops `deploy(migration)` 커밋 확인.

---

## Task 6: 통합 검증

전체 파이프라인이 끝까지 동작하는지 실제로 확인한다(절대원칙: 추측 아닌 실제 실행).

- [ ] **Step 1: gitops 전체 렌더 검증**

Run:
```
cd D:\workspace\dev-path-ai\devpath-gitops
for d in apps/*/base; do echo "== $d =="; kubectl kustomize "$d" >/dev/null && echo OK || echo FAIL; done
```
Expected: 모든 디렉토리(7 서비스 + frontend-admin 신설 + _migration) `OK`.

- [ ] **Step 2: ghcr 패키지 확인**

GitHub DevPathAi → Packages에서 다음 이미지가 `<sha>`·`main` 태그로 존재: 6개 백엔드(gateway/platform/learning/community/ai/sandbox) + devpath-frontend + devpath-frontend-admin + devpath-migration.

- [ ] **Step 3: gitops 커밋 이력 확인**

devpath-gitops 로그에 각 서비스의 `deploy(<svc>): <sha>` 커밋이 봇 계정으로 기록됐는지 확인.

- [ ] **Step 4: (클러스터 보유 시) ArgoCD 동기화 확인**

ArgoCD UI/CLI에서 9개 Application(서비스 7 + frontend-admin + _migration Job)이 Synced/Healthy. local-k8s(kind)로 검증 가능.

- [ ] **Step 5: 회귀 확인**

전 레포 main CI가 여전히 green(W1 검증 항목 회귀 없음). PR 시에는 image/deploy job이 스킵(`if: main`)되고 build만 도는지 확인.

---

## 자기 점검 메모 (작성자)

- **Spec 커버리지:** D1(범위)→Task1-5, D2(CI commit)→deploy job 전체, D3(migration 이미지)→Task5, D4(GitHub App)→Task0+deploy job, D5(SHA+main 태그)→image job tags, D6(main 트리거)→`if: github.ref`. frontend admin 신설→Task4. 모두 매핑됨.
- **미해결 결정:** Task2 Step6의 svc-template deploy job 포함 여부(실행 중 사용자 확인). Task3/4 커밋 순서(admin 디렉토리 선행 필요).
- **버전 주의(추측 금지로 실행 시 확인):** `actions/create-github-app-token`·`docker/build-push-action`·`setup-node`·kustomize 릴리스 태그는 실행 시점 최신/유효 버전을 확인 후 고정(W1에서 Maven 버전 확인했듯 Marketplace/릴리스 확인).

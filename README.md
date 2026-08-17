# devpath-shared

**DevPath AI** 공유 이벤트 스키마 + 공통 라이브러리 + 로컬 인프라 정의입니다.

## 구성

| 영역 | 내용 |
|------|------|
| `src/main/java/ai/devpath/shared/event` | Kafka(Outbox)로 발행되는 도메인 이벤트 스키마 |
| `docker-compose.yml` | 로컬 개발 인프라 (PostgreSQL 17, Redis 7, pgvector, Elasticsearch, Kafka KRaft) |

- Java 21 · Gradle (Kotlin DSL) · `java-library`
- 이벤트 스키마는 Java record + `DomainEvent` 인터페이스로 정의

## 사용

### 로컬 인프라 기동

```bash
docker compose up -d
```

| 서비스 | 포트 |
|--------|------|
| PostgreSQL (SSOT) | 5432 |
| Redis (세션/큐) | 6379 |
| pgvector (임베딩) | 5433 |
| Elasticsearch (BM25) | 9200 |
| Kafka (Event Bus) | 9092 |

> compose의 자격증명은 **로컬 개발 전용**입니다. 실제 환경 값은 절대 커밋하지 않습니다.

### 라이브러리 빌드

```bash
./gradlew build
```

서비스 레포는 GitHub Packages의 immutable Maven 좌표를 참조합니다.

### ET9 immutable package release

ET9 좌표 `ai.devpath:devpath-shared:0.0.1-et9.20260816`은 다음 세 Linux publication byte를 고정합니다.

| 파일 | bytes | SHA-256 |
|------|------:|---------|
| `devpath-shared-0.0.1-et9.20260816.jar` | 1,177,131 | `94e2adb769790d813a872163347ede20ad4c75ae88e5811df2ec6625a340f21f` |
| `devpath-shared-0.0.1-et9.20260816.pom` | 1,546 | `10daef2cdf7d436f952fa6dab10a27253a933af013093bb6967dd220010dbdd7` |
| `devpath-shared-0.0.1-et9.20260816.module` | 2,888 | `8c6445b67a674f8f65087728c5e602d9d3e06dd3c1a5bdbbe6d8f2d55779531c` |

PR CI는 Temurin `21.0.12+8`과 Gradle `9.5.1`로 clean build한 세 파일을 byte-for-byte 검증합니다. `main`의 첫 시도에서만 publish workflow가 실행되며, 원격 좌표가 완전히 없으면 게시하고 이미 있으면 세 파일이 모두 exact match일 때만 성공합니다. 일부만 존재하거나 한 byte라도 다른 좌표는 덮어쓰지 않고 실패합니다. 게시 후에는 인증된 GitHub Packages 다운로드로 세 파일을 다시 확인합니다.

실제 publish 전 저장소 관리자는 `mission-spine-shared-package-publish` environment에 required reviewer를 설정하고 `prevent_self_review=true`를 확인해야 합니다. 환경이 없거나 보호 규칙이 다르면 workflow는 package write 전에 fail closed 합니다. workflow rerun(`run_attempt > 1`)은 금지하며, 재시도는 새 `main` commit으로 수행합니다.

### Migration release gate

`main` CI는 source-SHA 태그의 migration image만 빌드하며 GitOps를 변경하지 않습니다. GitOps 변경은 `.github/workflows/mission-spine-migration-release.yml`의 수동 dispatch와 `mission-spine-migration-release` protected environment 승인 뒤에만 가능합니다. 이 workflow는 다음을 모두 확인합니다.

- Shared checkout이 입력 `source_sha`와 일치하는 현재 `main`의 첫 실행인지 확인
- GitOps release branch의 canonical candidate/release 2-file chain과 raw release-manifest SHA-256 확인
- sealed candidate의 Shared version/JAR hash/source와 migration image digest 확인
- 입력 `gitops_source_sha`가 현재 GitOps `main`인지 확인하고 candidate-bound digest만 변경
- `--force-with-lease` compare-and-swap으로 경쟁 변경을 거부

실행 전 `mission-spine-migration-release` environment에 required reviewer와 `prevent_self_review=true`를 설정하고, GitOps App의 `devpath-gitops` Contents write 권한을 검증해야 합니다. 이 저장소의 workflow는 seal을 만들지 않으며, main merge·package publish·migration deploy는 각각 별도 승인 경계입니다.

## 이벤트 추가 규칙

1. `ai.devpath.shared.event`에 record로 정의하고 `DomainEvent` 구현
2. `eventType`은 `<도메인>.<엔티티>.<동작>` 소문자 점 표기 (예: `learning.path.generated`)
3. 하위 호환을 깨는 필드 변경 금지 — 새 필드는 nullable/기본값으로 추가

## 개발 규칙

- Git 규칙: [documents/09_Git_규칙_정의서](https://github.com/DevPathAi/documents/blob/main/09_Git_규칙_정의서.md)
- 워크플로우 현황: `docs/project-management/` → [workflow-dashboard](https://devpathai.github.io/workflow-dashboard/)

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

서비스 레포에서는 추후 Maven 퍼블리시 또는 Gradle composite build로 참조합니다 (방식은 W1에서 확정 예정).

## 이벤트 추가 규칙

1. `ai.devpath.shared.event`에 record로 정의하고 `DomainEvent` 구현
2. `eventType`은 `<도메인>.<엔티티>.<동작>` 소문자 점 표기 (예: `learning.path.generated`)
3. 하위 호환을 깨는 필드 변경 금지 — 새 필드는 nullable/기본값으로 추가

## 개발 규칙

- Git 규칙: [documents/09_Git_규칙_정의서](https://github.com/DevPathAi/documents/blob/main/09_Git_규칙_정의서.md)
- 워크플로우 현황: `docs/project-management/` → [workflow-dashboard](https://devpathai.github.io/workflow-dashboard/)

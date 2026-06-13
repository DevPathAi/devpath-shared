# CLAUDE.md — devpath-shared

> 공유 이벤트 스키마 + 공통 라이브러리 + 로컬 인프라 정의

## 🚫 절대 조건 — 모든 작업에 예외 없이 적용

아래 세 가지는 이 레포의 **어떤 작업에도 우선하는 최상위 규칙**이다. 개별 지시가 이를 명시적으로 면제하지 않는 한 항상 따른다.

### 1. 추측·예상 금지
- 코드·설정·동작·의존성을 **추측하지 않는다.** 모르면 파일을 읽고 명령을 실행해 사실을 확인한 뒤 행동한다.
- "아마 ~일 것이다", "보통 ~하다" 같은 가정에 기반한 변경·답변·커밋을 금지한다.
- 확인이 불가능하면 진행을 멈추고 묻는다. 모르는 것을 아는 척하지 않는다.

### 2. 테스트 코드 우선 (Test-First)
- 모든 기능 추가·수정은 **실패하는 테스트를 먼저 작성**하고, 그 테스트를 통과시키는 최소 구현을 작성한다.
- 테스트 없는 구현 변경을 금지한다. 변경 후에는 반드시 테스트를 실행해 통과를 **눈으로 확인**한다.
- 구체적 테스트·검증 명령은 아래 "빌드·테스트" 절을 따른다.

### 3. 문제 발생 시 코드 분석 우선
- 버그·테스트 실패·예상 밖 동작이 생기면 **추측으로 고치지 않는다.** 먼저 관련 코드·로그·스택트레이스를 읽어 근본 원인을 규명한다.
- 증상만 덮는 임시방편(땜질)을 금지한다. 원인을 설명할 수 있을 때만 수정한다.

## 빌드·테스트

- 빌드: `./gradlew build`  / 테스트: `./gradlew test` (JUnit 5)
- 스택: Java 21 · Gradle (Kotlin DSL) · `java-library`
- 로컬 인프라: `docker compose up -d` (MySQL 8 / Redis 7 / pgvector / Elasticsearch / Kafka)

## 이벤트 추가 규칙

- `ai.devpath.shared.event`에 record로 정의하고 `DomainEvent`를 구현한다.
- `eventType`은 `<도메인>.<엔티티>.<동작>` 소문자 점 표기 (예: `learning.path.generated`).
- 하위 호환을 깨는 필드 변경 금지 — 새 필드는 nullable/기본값. **스키마 변경 시 직렬화 호환 테스트를 먼저 작성한다.**

## 공통 규칙

- Git: Conventional Commits — [documents/09_Git_규칙_정의서](https://github.com/DevPathAi/documents/blob/main/09_Git_규칙_정의서.md)
- 코드 리뷰: [documents/12_코드_리뷰_규칙](https://github.com/DevPathAi/documents/blob/main/12_코드_리뷰_규칙.md)
- 비밀값(Claude API 키·OAuth·결제 키)은 절대 커밋하지 않는다.


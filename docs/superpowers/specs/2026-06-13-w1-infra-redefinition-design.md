# W1 인프라 재정의 설계 (폴리레포 + PostgreSQL)

> **작성일**: 2026-06-13 · **대상 주차**: W1 (2026-06-15~06-19)
> **상태**: 승인됨 (브레인스토밍 → 구현 계획 대기)
> **선행 참고**: [documents/24_선행_트러블슈팅_참고](https://github.com/DevPathAi/documents/blob/main/24_선행_트러블슈팅_참고.md) (Synapse 78건)

---

## 1. 목표

17_스케줄 W1의 "기반 + 인프라 부트스트랩"을 **폴리레포 + PostgreSQL** 현실에 맞게 재정의한다. 레포 골격·docker-compose·CI는 이미 구축됐으므로, 본 스펙은 **DB 전환 · 의존성 배포 · 중앙 스키마 · 공통/법적 스키마 · 문서 동기화**를 다룬다.

## 2. 배경 (현재 상태)

| W1 작업 (17_스케줄) | 상태 |
|---|---|
| 모노리포 + Gradle 멀티프로젝트 | 폴리레포(devpath-* 9개)로 구축 — 본 스펙이 재정의 |
| Docker Compose 로컬 환경 | 완료 (MySQL 기반 — 본 스펙이 PG로 전환) |
| CI/CD 파이프라인 | 완료 (각 레포 ci.yml + gitops) |
| Flyway 초기 스키마 | 미착수 |
| 법적 분리보관 스키마 (정보통신망법 §29) | 미착수 |

## 3. 결정 사항

| 항목 | 결정 | 근거 |
|---|---|---|
| 의존성 관리 | shared → **GitHub Packages (Maven)** | 폴리레포 표준, 버전·CI 친화 |
| 스키마 소유 | **중앙집중** (devpath-shared) | 도메인 간 FK 강결합(user_id 전반, user_badges 공유) |
| DB | **MySQL → PostgreSQL** | 사용자 결정 |
| 임베딩 | **PG 2개 분리** (SSOT 5432 + pgvector 5433) | 임베딩 부하 격리 |
| 실행 접근 | **인프라 우선** (도메인 상세 스키마는 각 주차) | W1 본질은 기반 |

## 4. 컴포넌트 (각 독립 검증 가능)

### ① DB 전환 (MySQL → PostgreSQL)
- `devpath-shared/docker-compose.yml`: `mysql` 제거 → `postgres`(SSOT, 5432) + `postgres-vector`(pgvector/pgvector, 5433)
- 각 백엔드 서비스(`platform/learning/community/ai/sandbox`) `build.gradle.kts`: `com.mysql:mysql-connector-j` → `org.postgresql:postgresql`
- `application.yml`: `spring.datasource.url`(jdbc:postgresql), driver, `hibernate.dialect`(PostgreSQLDialect)
- **검증 (Synapse #10·#13 env 주입≠배선)**: 각 서비스에서 PG 키를 실제로 읽고 연결되는지 **Testcontainers PostgreSQL 통합 테스트**로 확인. compose 환경변수와 application.yml 키 일치 검사.

### ② shared 패키지 배포 (GitHub Packages)
- `devpath-shared/build.gradle.kts`: `maven-publish` 플러그인, `publishing { repositories { maven(GitHub Packages url) } }`, 그룹 `ai.devpath`, 아티팩트 `devpath-shared`
- publish 워크플로: `main` 푸시 또는 릴리즈 태그 시 `./gradlew publish`
- 각 서비스: `repositories { maven { url=GitHub Packages; credentials } }` + `implementation("ai.devpath:devpath-shared:<ver>")`
- 인증: CI는 `GITHUB_TOKEN`(actions), 로컬은 `~/.gradle/gradle.properties`의 PAT (레포에 **절대 커밋 금지**)
- 버전: SemVer. 초기 `0.0.1`.

### ③ 중앙 스키마 모듈 (Flyway · PostgreSQL)
- 위치: `devpath-shared/src/main/resources/db/migration`
- 단일 `flyway_schema_history`, 마이그레이션 SSOT
- **버전 네이밍 (Synapse #15 전역 버전 중복 방지)**: 타임스탬프 기반 `V<yyyyMMddHHmm>__<설명>.sql` (정수 순번 충돌 회피)
- **CI 가드 (Synapse #11 Flyway 침묵 실패)**: CI에서 `flyway validate` 실행 — core/starter 의존성 누락 시 실패하도록
- 실행 주체: 로컬 `./gradlew flywayMigrate`(flyway-gradle-plugin), 배포는 gitops **마이그레이션 Job**(서비스 부팅과 분리)
- 각 서비스는 **마이그레이션을 소유하지 않고** JPA 엔티티로 매핑만 (`ddl-auto: validate`)

### ④ 공통 + 법적 스키마 (W1 범위만)
- Flyway 셋업 + 공통 규약: `snake_case`, 모든 테이블 `created_at`/`updated_at`(timestamptz) audit 컬럼
- `users` **최소 골격**: `id`(bigserial), `github_id`, `status`, `created_at`, `last_active_at` — W2 OAuth가 확장
- **법적 (정보통신망법 §29)**: `dormant_user_archives`(3년 미이용 분리보관) + 배치 스케줄러용 메타 테이블
- 도메인 상세 스키마(02_ERD §2~9)는 W1 범위 밖 — 각 주차에 해당 서비스가 추가

### ⑤ 문서 동기화 (Synapse #9·#12 드리프트/픽션 방지)
- `documents`: 02_ERD·03_아키텍처의 MySQL → PostgreSQL 표기, 단일DB→PG 2개 갱신
- 각 서비스 README/CLAUDE.md의 MySQL 언급 갱신
- **원칙**: 코드 변경과 **같은 작업 단위(PR)**에서 문서 갱신. 검증 안 된 내용 기재 금지.

## 5. 의존 순서

```
① DB 전환(compose)
   ↓
② shared 패키지 배포  +  ③ 중앙 스키마 모듈
   ↓
각 서비스 의존 연결 (shared 참조 + PG 드라이버)
   ↓
④ 공통/법적 마이그레이션 + Testcontainers 테스트
   ↓
⑤ 문서 동기화
```

## 6. 검증 전략 (절대조건: 테스트 우선)

- **스키마**: Testcontainers PostgreSQL로 마이그레이션 적용 + 엔티티 검증 테스트를 **먼저** 작성
- **각 서비스**: `./gradlew build` (PG 드라이버, shared 의존)
- **로컬 E2E**: `docker compose up` → `flywayMigrate` 성공 → 서비스 부팅(`ddl-auto: validate` 통과)
- **shared publish**: CI dry-run
- **문서**: PG 전환 누락 grep 점검 (`MySQL`/`mysql` 잔존 검색)

## 7. Synapse 교훈 매핑 (위험 → 가드)

| Synapse 함정 | 본 스펙 가드 |
|---|---|
| #11 Flyway core/starter 침묵 실패 | CI `flyway validate` |
| #15 전역 버전 중복 | 타임스탬프 버전 네이밍 |
| #10·#13 env 주입 ≠ 배선 | Testcontainers 통합 테스트 |
| #9·#12 문서 드리프트/픽션 | 코드-문서 동일 PR |
| #3 Boot4 메이저 연쇄 | Jackson3·ArchUnit BOM 고정 |
| #1·#23 이미지 태그 비결정성 | gitops 커밋 SHA 불변 태그 |
| #4 gradlew 권한 | (해결됨) 신규 레포 `chmod +x` |

## 8. W1 범위 밖 (명시)

- 도메인별 상세 스키마(OAuth users 확장, github_profiles, 콘텐츠, 커뮤니티 등) → 각 주차
- 실제 OAuth2 구현(W2), GitHub 수집(W3)
- Kafka 토픽/Outbox 발행 로직(W2+) — 단 토픽 환경 프리픽스 규약은 그때 Synapse #199 참고
- ES/Redis 스키마·인덱스 (해당 기능 주차)

## 9. 성공 기준

1. `docker compose up`으로 PG 2개(SSOT·벡터) + Redis·ES·Kafka 기동
2. `flywayMigrate`로 공통+법적 스키마 적용, `flyway validate` 통과
3. 모든 백엔드 서비스 `./gradlew build` 그린 (PG 드라이버 + shared 의존)
4. 최소 1개 서비스가 PG 연결 + 마이그레이션된 스키마를 `ddl-auto: validate`로 부팅
5. 02_ERD·03_아키텍처에 MySQL 잔존 0건
6. CI 그린 (validate 가드 포함)

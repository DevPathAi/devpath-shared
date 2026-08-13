# 운영 시드 한국어 교정 설계

**작성일:** 2026-08-13
**대상 레포:** `devpath-shared` (마이그레이션·테스트) — 데이터 원본은 `devpath-learning-svc`

## 문제

운영 DB의 진단 문항 500개와 학습 콘텐츠 150개가 **영어 더미**다. 이용자가 실력 진단을 시작하면
영어로 된, 내용이 없는 문항을 본다.

문항은 500개 전부 같은 템플릿이다.

```
BACKEND_SPRING 009: Which option best applies concurrency in a DevPath diagnostic scenario?
["Apply the primary concept deliberately", "Ignore the signal and continue",
 "Disable validation around the flow", "Move responsibility to an unrelated layer"]
```

**선택지 4개가 500문항에서 모두 동일하고 정답 인덱스만 무작위로 다르다.** 풀어서 맞힐 수 있는
문제가 아니며 진단 결과도 의미가 없다. 본문에 폐기된 브랜드 `DevPath`가 350회 노출된다.
학습 콘텐츠 150개도 같은 상태다(`DevPath` 150회).

## 원인

**콘텐츠 생성이 실패한 것이 아니라 배포가 어긋났다.** 제대로 된 한국어 원본이 이미 승인돼
레포에 있다.

| 파일 | 줄수 | 한국어 | 영어 템플릿 |
|---|---|---|---|
| `learning-svc` 클래스패스 시드 (dev 프로파일) | 2346 | 709 | 0 |
| `shared` 마이그레이션 `V202607281001` (운영) | 508 | 2 | 350 |

`V202607281001`·`V202607281002`는 "dev 프로파일 시더의 운영 미적용 갭 복구"로 만들어졌는데,
**한국어 재생성 이후의 시드가 아니라 그 이전의 영어 파일에서 만들어졌다.**
로컬(dev)에서는 한국어로 보이고 운영에서만 영어라 발견이 늦었다.

## 재발을 못 막은 이유

`FlywayMigrationTest.questionBankSeeded()`가 **개수만** 검사한다.

```java
assertTrue(rs.getLong(1) >= 500, "question_bank는 500문항 이상 시드되어야 한다");
```

500개가 전부 무의미해도 통과한다. `contentsSeeded()`도 같다.

## 데이터 원본 (신규 생성 없음)

- 문항: `devpath-learning-svc/src/main/resources/db/seed/question_bank_md2_seed.sql`
- 콘텐츠: `devpath-learning-svc/src/main/resources/db/seed/content_md2_seed.sql`

둘 다 승인 JSONL(`tools/content-gen/generated/approved/*.jsonl`)에서 결정적으로 생성된
산출물이며 dev 프로파일 시더가 이미 사용 중이다.

두 파일의 `INSERT` 컬럼 목록은 기존 마이그레이션과 **정확히 일치**하므로 본문을 그대로 옮기면 된다.

```sql
INSERT INTO question_bank (track, question_type, content, options, answer_key, bloom_level, difficulty, concept_tags) VALUES
INSERT INTO contents (slug, title, track, content_md, estimated_minutes, difficulty, bloom_level, concept_tags, status) VALUES
```

### RAG 임베딩도 함께 적재한다

`content_md2_seed.sql`(2.1MB)은 단일 INSERT 가 아니다. **`contents` 1건 + `content_embeddings` 238건**이
들어 있고, 각 임베딩은 `SELECT c.id ... FROM contents c WHERE c.slug = '...'` 로 방금 삽입한
콘텐츠를 찾아 붙는다.

기존 운영 마이그레이션 `V202607281002`는 "임베딩은 제외(후속 Ollama 백필)"라며 뺐고,
그래서 **운영 `content_embeddings` 가 0건**이다. 콘텐츠 유사도 검색이 동작하지 않는 상태다.

임베딩은 합성 픽스처가 아니라 실제 값임을 확인했다.

| 확인 | 값 |
|---|---|
| 행수 | 238 |
| 차원 | 768 (`VECTOR(768)` 컬럼과 일치) |
| 서로 다른 벡터 | 238 / 238 |
| 표준편차(행0) | 0.726 |
| 생성 모델 | `nomic-embed-text` (`tools/content-gen/README.md`) |
| 런타임 모델 | `nomic-embed-text` (`ai-svc` `embed-model` 기본값) |

생성 모델과 런타임 질의 모델이 같으므로 시드 벡터와 런타임 벡터가 같은 공간에 있다.
이 마이그레이션이 이월돼 있던 "임베딩 백필"을 함께 해소한다.

원본 실측값:

| 항목 | 값 |
|---|---|
| 문항 총수 | 500 (5트랙 × 100) |
| 본문에 한글 포함 | 500 / 500 |
| 서로 다른 options 조합 | 496 |
| `Which option best applies` | 0 |
| `DevPath` | 0 |
| 콘텐츠 총수 | 150 |
| 본문에 한글 포함 | 150 / 150 |
| 콘텐츠 `DevPath` | 0 |

## 설계

### 마이그레이션 (신규 1개)

`src/main/resources/db/migration/V202608131001__reseed_korean_seed_data.sql`

삭제 순서는 FK 실측으로 정한다. `assessment_items.question_bank_id` 와
`path_weekly_tasks.content_id` 에는 `ON DELETE CASCADE` 가 **없어서** 참조를 먼저 끊어야 한다.

```sql
DELETE FROM learning_paths;   -- → path_milestones → path_weekly_tasks (CASCADE)
DELETE FROM assessments;      -- → assessment_items · assessment_results (CASCADE)
DELETE FROM question_bank;
INSERT INTO question_bank (...) VALUES ...;   -- 한국어 500

DELETE FROM contents;         -- → content_embeddings · user_content_progress (CASCADE)
INSERT INTO contents (...) VALUES ...;        -- 한국어 150
INSERT INTO content_embeddings (...) SELECT ... FROM contents c WHERE c.slug = '...';  -- 238건
```

**`IF count = 0` 가드를 쓰지 않는다.** 기존 시드 마이그레이션에는 그 가드가 있는데,
이미 500행이 있는 상태라 가드를 그대로 두면 아무 일도 일어나지 않는다.
이번 것은 "비었을 때만 채움"이 아니라 "교체"다.

기존 마이그레이션 `V202607281001`·`V202607281002`는 **수정하지 않는다.**
이미 적용된 마이그레이션을 고치면 Flyway 체크섬 검증이 깨진다.

### 재발 방지 테스트 (`FlywayMigrationTest` 보강)

개수 단언은 남기고 품질 단언을 추가한다.

| 대상 | 단언 |
|---|---|
| `question_bank` | 본문에 한글이 있는 행 ≥ 500 |
| | `Which option best applies` 를 포함한 행 0 |
| | `DevPath` 를 포함한 행 0 |
| | 서로 다른 `options` 조합 ≥ 450 |
| `contents` | 본문에 한글이 있는 행 ≥ 150 |
| | `DevPath` 를 포함한 행 0 |
| `content_embeddings` | 행수 ≥ 200 |
| | 서로 다른 `embedding` 값 ≥ 200 (모두 같은 벡터를 넣는 사고 탐지) |

**"전부"가 아니라 "시드 분량 이상"으로 단언하는 이유**: `FlywayMigrationTest` 의 다른 테스트들이
`contents` 에 픽스처 행(`'smoke-…'`·`'ucp-…'`, 본문 `'m'`)을 넣고 지운다. 그 테스트가 중간에
실패하면 정리가 안 돼 한국어 아닌 행이 남고, `= 전체 행` 단언은 그때 시드와 무관한 이유로
실패한다. `≥ 시드 분량` 은 시드 500(150)개 중 하나라도 한국어가 아니면 잡으면서 픽스처에는
영향받지 않는다. 반면 템플릿·`DevPath` 단언은 픽스처가 만들 수 없는 문자열이므로 **정확히 0**을
유지한다.

「서로 다른 options 조합」이 이번 사고의 본질을 직접 겨냥한다 — 옛 시드는 500문항이
선택지 1종을 공유했다. 개수·언어만 봐서는 그 상태를 잡지 못한다.

임계값 450은 실측 496에 여유를 둔 값이다. 중복 선택지가 50개를 넘으면 출제 품질 문제로 본다.

### Flyway placeholder 치환 — 네 개의 실행 경로

승인된 한국어 콘텐츠에는 JS·Dart 템플릿 리터럴이 **정상적인 코드 예시**로 들어 있다
(`${response.status}`·`${count}`·`${bloc.count}`·`${maven.build.timestamp}` 등 31줄/33회).
Flyway 는 기본값(`placeholderReplacement=true`)에서 이것을 치환 대상으로 해석해 파싱에 실패한다.
기존 마이그레이션 42개 중 `${` 를 쓰는 것은 0건이라 지금까지 드러나지 않았다.

이 SQL 이 실행되는 경로는 **넷**이다.

| 경로 | 어디서 | 설정 |
|---|---|---|
| 운영 마이그레이션 잡 | `flyway/flyway:11-alpine` CLI | `Dockerfile.migration` 의 `ENV FLYWAY_PLACEHOLDER_REPLACEMENT=false` |
| shared 테스트 | `FlywayMigrationTest` | `migrate()` 헬퍼의 `.placeholderReplacement(false)` |
| 로컬 Gradle | `./gradlew flywayMigrate` | `build.gradle.kts` 의 `flyway { placeholderReplacement = false }` |
| **소비 서비스 테스트** | 7개 svc 의 `spring.flyway`(`classpath:db/migration`) | **스크립트 설정 파일** |

네 번째가 결정적이다. SQL 은 `src/main/resources` 아래라 **jar 에 실려** 소비 서비스 테스트에서
`spring.flyway` **기본 설정**으로 실행된다. 소비 레포에는 자체 마이그레이션도 placeholder 설정도 없다.
앞의 세 설정은 이 경로에 닿지 않는다.

그래서 마이그레이션 옆에 스크립트 설정 파일을 둔다.

```
src/main/resources/db/migration/V202608131001__reseed_korean_seed_data.sql.conf
placeholderReplacement=false
```

이 파일은 `src/main/resources` 아래이므로 jar·도커 이미지·클래스패스에 함께 실려 **네 경로를 모두 덮는다.**
운영과 같은 `flyway/flyway:11-alpine` 이미지에서 환경변수 없이 이 파일만으로 43개 마이그레이션이
전부 적용되는 것을 실증했다.

`FlywayMigrationTest.migrationsWithPlaceholderSyntaxCarryScriptConfig()` 가 이 규약을 강제한다 —
`${...}` 를 담은 마이그레이션에 짝이 되는 `.conf` 가 없으면 red 다.

## 운영 영향

| 테이블 | 운영 행수 | 이 마이그레이션의 영향 |
|---|---|---|
| `assessments` | 9 (전부 `user_id=1` 본인 테스트) | 삭제 |
| `assessment_items` | 42 | CASCADE 삭제 |
| `assessment_results` | — | CASCADE 삭제 |
| `question_bank` | 500 | 교체 |
| `contents` | 150 | 교체 |
| `learning_paths` | 0 | 실제 삭제 없음 |
| `content_embeddings` | 0 | **238건 신규 적재** (이월돼 있던 백필 해소) |
| `user_content_progress` | 0 | 실제 삭제 없음 |
| `sandbox_sessions` | 0 | 영향 없음 |
| `ai_mentor_sessions.content_id` | 미측정 | FK 없는 논리 참조 — 교체 후 고아 참조가 된다(id 재사용 없음, 오염 아님) |

지워지는 이력은 **무의미한 문항으로 산출된 본인 테스트 결과**뿐이고, 그로부터 파생된
학습 경로는 존재하지 않는다.

`QuestionBankSeeder`(dev 프로파일)는 `count >= 500` 이면 조기 반환하므로 영향받지 않는다.

## 검증

1. **TDD**: 품질 단언을 먼저 추가하고 로컬 postgres에서 red 확인 → 마이그레이션 추가 → green
2. `./gradlew test` 전체 통과
3. 배포 후 운영 DB에서 한국어 문항 수·템플릿 0건·`DevPath` 0건·임베딩 238건 실측
4. 앱에서 진단 1회 실행해 한국어 문항이 나오는지 육안 확인
5. **잡 실행 직전 재측정 게이트.** 아래 「운영 영향」 표는 2026-08-13 실측이다. 머지와 배포 사이에
   이용자가 학습 경로를 생성하거나 콘텐츠를 열면 그 행이 CASCADE 로 **조용히 사라진다.**
   잡을 돌리기 직전에 네 값을 다시 재고, 0 이 아니면 멈추고 판단한다.

   ```sql
   SELECT (SELECT count(*) FROM learning_paths)        AS learning_paths,
          (SELECT count(*) FROM user_content_progress) AS progress,
          (SELECT count(*) FROM assessments)           AS assessments,
          (SELECT count(*) FROM content_embeddings)    AS embeddings;
   ```

## 배포

`shared` `develop` → `main` 릴리스 → 마이그레이션 이미지 빌드 → 잡 실행.

ArgoCD가 관리하는 `devpath-flyway-migrate` Job은 `spec.template` 이 immutable 이라
이미지 태그가 바뀌면 sync 가 실패할 뿐 자동 실행되지 않는다. 실행은 수동이다
(2026-08-13 이용약관 배포 세션에서 확인).

적용 전 대상 테이블 스냅샷을 파일로 남긴다.

## 범위 밖

같은 보고에서 함께 나온 다음 두 가지는 이 스펙에 포함하지 않는다. 별도 설계 대상이다.

- **진단 트랙 선택**: `diagnostic_page.dart:137-138` 이 트랙을 `'BACKEND_SPRING'` 으로
  하드코딩한다. 뱅크에는 5트랙이 모두 있고 API도 트랙을 인자로 받는데 화면이 선택지를 주지 않는다.
- **베타 신청 스택 연결**: 홈페이지 리드 폼의 `stack` 은 자유 텍스트(선택 입력)이고
  Google Sheet 로만 간다. 앱 계정과 이어지는 경로가 없다.

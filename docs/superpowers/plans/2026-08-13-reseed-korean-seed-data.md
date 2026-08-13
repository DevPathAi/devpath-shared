# 운영 시드 한국어 교정 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 운영 DB에 영어 더미로 적재된 진단 문항 500개와 학습 콘텐츠 150개를 이미 승인된 한국어 원본으로 교체하고, 같은 사고가 재발하면 CI가 잡도록 품질 단언을 추가한다.

**Architecture:** `devpath-shared`에 교체 마이그레이션 1개를 추가한다. SQL 본문은 `devpath-learning-svc`의 클래스패스 시드 파일(승인 JSONL에서 결정적으로 생성된 산출물)을 그대로 옮긴다. 새 콘텐츠를 만들지 않는다. 기존 `FlywayMigrationTest`는 시드 **개수만** 검사해 이 사고를 놓쳤으므로, 언어·템플릿·선택지 다양성을 보는 품질 단언을 추가한다.

**Tech Stack:** Flyway (PostgreSQL 17 + pgvector) · Java 21 · JUnit 5 · Gradle (Kotlin DSL)

**설계 문서:** `docs/superpowers/specs/2026-08-13-reseed-korean-seed-data-design.md`

## Global Constraints

이 절의 값은 모든 Task의 요구사항에 암묵적으로 포함된다.

- 작업은 `devpath-shared` 레포의 `fix/reseed-korean-seed-data` 브랜치에서 진행한다. 이 브랜치는 이미 존재하고 설계 문서 커밋(`f7385c5`)이 올라가 있다. **새 브랜치를 만들지 않는다.**
- **기존 마이그레이션 파일을 수정하지 않는다.** 이미 적용된 마이그레이션을 고치면 Flyway 체크섬 검증이 깨진다. `V202607281001__seed_question_bank.sql`·`V202607281002__seed_contents.sql`은 그대로 둔다.
- 새 마이그레이션 파일명은 `V202608131001__reseed_korean_seed_data.sql` 이다.
- 데이터 원본은 `D:\workspace\dpa\devpath-learning-svc\src\main\resources\db\seed\` 의 두 파일이다. **내용을 손으로 고치거나 재생성하지 않는다.** 그대로 옮긴다.
- 커밋 메시지는 Conventional Commits, 본문은 한국어.
- 모든 git·파일 명령에 **절대경로** 또는 `git -C <레포 절대경로>` 를 쓴다. `cd` 후 상대경로로 후속 명령을 내지 않는다.
- 테스트에는 PostgreSQL이 필요하다. 로컬은 `docker compose up -d postgres`(5432), 접속 정보는 `DB_URL`/`DB_USER`/`DB_PASSWORD` 환경변수이며 기본값은 `jdbc:postgresql://localhost:5432/devpath` · `devpath` · `localdev` 다.

---

## File Structure

| 레포 | 파일 | 책임 |
|---|---|---|
| shared | `src/main/resources/db/migration/V202608131001__reseed_korean_seed_data.sql` (신설) | 옛 시드 삭제 + 한국어 문항·콘텐츠·임베딩 적재 |
| shared | `src/test/java/ai/devpath/shared/db/FlywayMigrationTest.java` (수정) | 시드 **품질** 단언 — 개수만 보던 기존 단언 보강 · 마이그레이션 헬퍼 |
| shared | `Dockerfile.migration` (수정) | 운영 Flyway 의 placeholder 치환을 끈다 |
| learning-svc | `src/main/resources/db/seed/question_bank_md2_seed.sql` (읽기 전용) | 문항 SQL 원본 |
| learning-svc | `src/main/resources/db/seed/content_md2_seed.sql` (읽기 전용) | 콘텐츠 + 임베딩 SQL 원본 |

---

### Task 1: 시드 품질 단언 추가 (red 확인)

기존 `questionBankSeeded()`·`contentsSeeded()`는 개수만 본다. 500개가 전부 무의미해도 통과한다. **먼저 품질 단언을 넣고 현재 상태에서 실패하는 것을 눈으로 본다.** 마이그레이션은 Task 2에서 만든다.

**Files:**
- Modify: `src/test/java/ai/devpath/shared/db/FlywayMigrationTest.java`

**Interfaces:**
- Consumes: 없음
- Produces: `questionBankSeedIsKorean()` · `contentSeedIsKorean()` · `contentEmbeddingsSeeded()` 세 테스트. Task 2가 이 셋을 green으로 만든다.

- [ ] **Step 1: 로컬 PostgreSQL을 띄운다**

```bash
cd /d/workspace/dpa/devpath-shared && docker compose up -d postgres
```

컨테이너가 뜨는 것을 확인한다.

```bash
docker compose ps postgres
```

Expected: `postgres` 서비스가 `running` 상태.

- [ ] **Step 2: 실패하는 테스트 3개를 쓴다**

`FlywayMigrationTest.java` 의 마지막 `}` 직전에 아래 세 메서드를 추가한다. 파일 안의 다른 테스트와 같은 방식(먼저 `migrate()` 호출 후 결과 상태 검증)을 따른다.

```java
  /**
   * 시드 문항의 품질. 개수만 보던 questionBankSeeded()가 놓친 것을 잡는다.
   *
   * <p>2026-08-13 사고: 운영에 적재된 500문항이 전부 같은 영어 템플릿이었고
   * 선택지 4개가 500문항에서 동일했다(정답 인덱스만 무작위). 개수 단언은 통과했다.
   */
  @Test
  void questionBankSeedIsKorean() throws Exception {
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      try (var rs = st.executeQuery(
          "SELECT count(*) AS total,"
              + " count(*) FILTER (WHERE content ~ '[가-힣]') AS korean,"
              + " count(*) FILTER (WHERE content LIKE '%Which option best applies%') AS template,"
              + " count(*) FILTER (WHERE content LIKE '%DevPath%') AS old_brand"
              + " FROM question_bank")) {
        assertTrue(rs.next(), "집계 결과 필요");
        long total = rs.getLong("total");
        assertTrue(total >= 500, "문항은 500개 이상이어야 한다 (실제: " + total + ")");
        // 같은 DB 를 쓰는 다른 테스트가 픽스처 행을 남길 수 있으므로 "전부"가 아니라
        // "시드 분량 이상"으로 단언한다. 시드 500개 중 하나라도 한국어가 아니면
        // korean < 500 이 되어 잡힌다.
        assertTrue(rs.getLong("korean") >= 500,
            "한국어 문항이 500개 이상이어야 한다 (한국어: " + rs.getLong("korean") + " / " + total + ")");
        assertTrue(rs.getLong("template") == 0,
            "제네릭 영어 템플릿 문항이 남아 있으면 안 된다 (실제: " + rs.getLong("template") + ")");
        assertTrue(rs.getLong("old_brand") == 0,
            "폐기된 브랜드 DevPath가 노출되면 안 된다 (실제: " + rs.getLong("old_brand") + ")");
      }
      // 선택지가 모든 문항에서 동일했던 것이 이번 사고의 본질이다.
      try (var rs = st.executeQuery(
          "SELECT count(DISTINCT options::text) AS distinct_options FROM question_bank")) {
        assertTrue(rs.next(), "집계 결과 필요");
        long distinct = rs.getLong("distinct_options");
        assertTrue(distinct >= 450,
            "서로 다른 선택지 조합이 450개 이상이어야 한다 (실제: " + distinct + ")");
      }
    }
  }

  /** 시드 콘텐츠의 품질. 문항과 같은 사고가 콘텐츠 150개에도 있었다. */
  @Test
  void contentSeedIsKorean() throws Exception {
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
    try (var c = dataSource().getConnection(); var st = c.createStatement();
        var rs = st.executeQuery(
            "SELECT count(*) AS total,"
                + " count(*) FILTER (WHERE content_md ~ '[가-힣]') AS korean,"
                + " count(*) FILTER (WHERE content_md LIKE '%DevPath%') AS old_brand"
                + " FROM contents")) {
      assertTrue(rs.next(), "집계 결과 필요");
      long total = rs.getLong("total");
      assertTrue(total >= 150, "콘텐츠는 150개 이상이어야 한다 (실제: " + total + ")");
      // 이 파일의 다른 테스트가 contents 에 픽스처 행('smoke-…'·'ucp-…', 본문 'm')을
      // 넣고 지운다. 그 테스트가 중간에 실패하면 행이 남으므로 "전부"로 단언하지 않는다.
      assertTrue(rs.getLong("korean") >= 150,
          "한국어 콘텐츠가 150개 이상이어야 한다 (한국어: " + rs.getLong("korean") + " / " + total + ")");
      assertTrue(rs.getLong("old_brand") == 0,
          "폐기된 브랜드 DevPath가 노출되면 안 된다 (실제: " + rs.getLong("old_brand") + ")");
    }
  }

  /**
   * RAG 임베딩 시드. 운영은 0건이었다(옛 마이그레이션이 임베딩을 제외했다).
   * 모든 행이 같은 벡터인 경우를 함께 막는다 — 그러면 유사도 검색이 무의미해진다.
   */
  @Test
  void contentEmbeddingsSeeded() throws Exception {
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
    try (var c = dataSource().getConnection(); var st = c.createStatement();
        var rs = st.executeQuery(
            "SELECT count(*) AS total, count(DISTINCT embedding::text) AS distinct_vec"
                + " FROM content_embeddings")) {
      assertTrue(rs.next(), "집계 결과 필요");
      long total = rs.getLong("total");
      assertTrue(total >= 200, "임베딩은 200건 이상 시드되어야 한다 (실제: " + total + ")");
      // 모든 행이 같은 벡터면 유사도 검색이 무의미해진다.
      // contentEmbeddingsCosineSmoke 가 남길 수 있는 픽스처 1행을 감안해 >= 로 둔다.
      assertTrue(rs.getLong("distinct_vec") >= 200,
          "서로 다른 임베딩 벡터가 200개 이상이어야 한다 (서로 다른 값: "
              + rs.getLong("distinct_vec") + " / " + total + ")");
    }
  }
```

- [ ] **Step 3: 테스트를 돌려 red를 눈으로 확인한다**

```bash
cd /d/workspace/dpa/devpath-shared && ./gradlew test --tests '*FlywayMigrationTest*'
```

Expected: FAIL. 세 테스트가 모두 실패한다.
- `questionBankSeedIsKorean` — "한국어 문항이 500개 이상이어야 한다 (한국어: 0 / 500)"
- `contentSeedIsKorean` — "한국어 콘텐츠가 150개 이상이어야 한다 (한국어: 0 / 150)"
- `contentEmbeddingsSeeded` — "임베딩은 200건 이상 시드되어야 한다 (실제: 0)"

> 실패 메시지에 위 숫자가 보이지 않으면 DB가 옛 시드 상태가 아닌 것이다. `docker compose down -v postgres && docker compose up -d postgres` 로 초기화하고 다시 돌린다.
> (dev 프로파일 시더가 먼저 한국어를 넣어 둔 로컬 DB라면 `IF count = 0` 가드 때문에 영어 시드가 적재되지 않아 red가 나오지 않는다. 반드시 초기화한 DB로 확인한다.)

> 기존 `questionBankSeeded`·`contentsSeeded`는 계속 통과한다. 그것이 이 사고를 놓친 이유다 — 개수만 보기 때문이다.

**참고 — 운영 DB 실측값(2026-08-13):** 세 표현식이 실제로 동작하는 것과 결함의 크기를 운영에서 직접 쟀다.

| 표현식 | 운영 실측 |
|---|---|
| `count(*) FILTER (WHERE content ~ '[가-힣]')` | **0** / 500 |
| `count(DISTINCT options::text)` | **1** — 500문항이 선택지 한 벌을 공유한다 |
| `count(*) FROM content_embeddings` | **0** |

`distinct_options = 1` 이 이번 사고의 본질이다. 단언 임계값 450과 비교하면 압도적으로 미달한다.

- [ ] **Step 4: 커밋**

```bash
git -C /d/workspace/dpa/devpath-shared add src/test/java/ai/devpath/shared/db/FlywayMigrationTest.java
git -C /d/workspace/dpa/devpath-shared commit -m "test(seed): 시드 품질 단언을 추가한다

개수만 보던 questionBankSeeded/contentsSeeded 는 500문항이 전부 같은
영어 템플릿이어도 통과했다. 언어·템플릿 부재·선택지 다양성·임베딩
벡터 다양성을 단언해 같은 사고를 CI 에서 잡는다.

이 커밋 시점에는 세 테스트가 red 다. 교체 마이그레이션이 green 으로 만든다."
```

---

### Task 2: 교체 마이그레이션 작성

**Files:**
- Create: `src/main/resources/db/migration/V202608131001__reseed_korean_seed_data.sql`

**Interfaces:**
- Consumes: Task 1이 추가한 세 테스트
- Produces: 한국어 문항 500 · 콘텐츠 150 · 임베딩 238이 적재된 DB 상태

> **이 Task는 편집기로 파일을 붙여넣지 않는다.** 원본 두 파일은 262KB·2.1MB다.
> 아래 셸 명령으로 이어 붙인다. 손으로 옮기면 인코딩·개행이 깨지고 내용이 잘린다.

- [ ] **Step 1: 마이그레이션 파일의 머리말을 만든다**

아래 명령을 그대로 실행한다. 따옴표 없는 heredoc(`<<'SQL'`)이라 `$`·백틱이 그대로 들어간다.

```bash
cat > /d/workspace/dpa/devpath-shared/src/main/resources/db/migration/V202608131001__reseed_korean_seed_data.sql <<'SQL'
-- 운영 시드 한국어 교정.
--
-- V202607281001·V202607281002 는 "dev 프로파일 시더의 운영 미적용 갭 복구"로
-- 만들어졌는데, 한국어 재생성 이후의 시드가 아니라 그 이전의 영어 파일에서
-- 만들어졌다. 그 결과 운영에는 진단 문항 500개와 학습 콘텐츠 150개가 영어
-- 더미로 적재됐다. 문항은 500개가 선택지 1종을 공유하고 정답 인덱스만
-- 무작위로 달라, 풀어서 맞힐 수 없고 진단 결과도 의미가 없었다.
--
-- 이 마이그레이션은 "비었을 때만 채움"이 아니라 "교체"다.
-- 기존 시드 마이그레이션과 달리 IF count = 0 가드를 쓰지 않는다 —
-- 이미 500행이 있는 상태라 가드를 두면 아무 일도 일어나지 않는다.
--
-- 삭제 순서는 FK 실측으로 정했다. assessment_items.question_bank_id 와
-- path_weekly_tasks.content_id 에는 ON DELETE CASCADE 가 없어 참조를 먼저 끊는다.
--
-- 원본: devpath-learning-svc/src/main/resources/db/seed/
--       question_bank_md2_seed.sql · content_md2_seed.sql
--       (승인 JSONL tools/content-gen/generated/approved/*.jsonl 에서 결정적으로 생성)

DELETE FROM learning_paths;   -- → path_milestones → path_weekly_tasks (CASCADE)
DELETE FROM assessments;      -- → assessment_items · assessment_results (CASCADE)
DELETE FROM question_bank;

SQL
```

> 마지막 `SQL` 은 heredoc 종결자다. **줄 맨 앞(들여쓰기 없이)** 에 와야 한다.

- [ ] **Step 2: 문항 SQL 본문을 이어 붙인다**

원본은 262KB다. 셸로 이어 붙인다.

```bash
cat /d/workspace/dpa/devpath-learning-svc/src/main/resources/db/seed/question_bank_md2_seed.sql \
  >> /d/workspace/dpa/devpath-shared/src/main/resources/db/migration/V202608131001__reseed_korean_seed_data.sql
```

원본은 다음 한 줄로 시작하며, 컬럼 목록이 기존 마이그레이션과 정확히 일치하므로 **변환하지 않는다.**

```sql
INSERT INTO question_bank (track, question_type, content, options, answer_key, bloom_level, difficulty, concept_tags) VALUES
```

붙인 뒤 끝이 세미콜론인지 확인한다.

```bash
tail -c 120 /d/workspace/dpa/devpath-shared/src/main/resources/db/migration/V202608131001__reseed_korean_seed_data.sql
```

Expected: 마지막 문자가 `;` 다. 아니면 다음 줄로 세미콜론을 추가한다.

```bash
printf ';\n' >> /d/workspace/dpa/devpath-shared/src/main/resources/db/migration/V202608131001__reseed_korean_seed_data.sql
```

- [ ] **Step 3: 콘텐츠 삭제문을 잇는다**

```bash
cat >> /d/workspace/dpa/devpath-shared/src/main/resources/db/migration/V202608131001__reseed_korean_seed_data.sql <<'SQL'

DELETE FROM contents;         -- → content_embeddings · user_content_progress (CASCADE)

SQL
```

- [ ] **Step 4: 콘텐츠 + 임베딩 SQL 본문을 이어 붙인다**

원본은 2.1MB이고 **단일 INSERT가 아니다.**

- `INSERT INTO contents (...) VALUES ...` 1건
- `INSERT INTO content_embeddings (...) SELECT c.id, ... FROM contents c WHERE c.slug = '...';` 238건

임베딩 INSERT는 방금 삽입한 콘텐츠를 slug로 찾아 붙으므로 **콘텐츠 INSERT 뒤에 와야 한다.**
원본 파일의 순서가 이미 그렇다. 순서를 바꾸지 않는다.

```bash
cat /d/workspace/dpa/devpath-learning-svc/src/main/resources/db/seed/content_md2_seed.sql \
  >> /d/workspace/dpa/devpath-shared/src/main/resources/db/migration/V202608131001__reseed_korean_seed_data.sql
```

- [ ] **Step 5: 파일 구조를 확인한다**

```bash
f=/d/workspace/dpa/devpath-shared/src/main/resources/db/migration/V202608131001__reseed_korean_seed_data.sql
grep -c "^DELETE FROM" $f
grep -o "^INSERT INTO [a-z_]*" $f | sort | uniq -c
grep -c "IF (SELECT count" $f
```

Expected:
- `DELETE FROM` **4**건 (learning_paths · assessments · question_bank · contents)
- `INSERT INTO question_bank` 1 · `INSERT INTO contents` 1 · `INSERT INTO content_embeddings` 238
- `IF (SELECT count` **0**건 — 가드가 있으면 안 된다

- [ ] **Step 5b: Flyway placeholder 치환을 끈다 (운영 이미지)**

> **왜 필요한가 (2026-08-13 실증).** 승인된 한국어 콘텐츠에는 JS·Dart 템플릿 리터럴이
> **정상적인 코드 예시**로 들어 있다 — `` `HTTP error! status: ${response.status}` ``,
> `${count}`, `${bloc.count}`, `${maven.build.timestamp}` 등 31곳. Flyway 는 기본값
> (`placeholderReplacement=true`)에서 SQL 본문의 `${...}` 를 치환 대상 placeholder 로 해석해
> 파싱에 실패한다. 운영과 같은 `flyway/flyway:11-alpine` 이미지로 재현·해결을 실증했다.
>
> ```
> ON  → ERROR: Unable to parse statement ... No value provided for placeholder: ${response.status}
> OFF → Successfully applied 43 migrations to schema "public", now at version v202608131001
> ```
>
> 기존 마이그레이션 39개 중 `${` 를 쓰는 것은 **0건**이라 치환을 꺼도 잃는 기능이 없다.

`Dockerfile.migration` 에 환경변수 한 줄을 추가한다. 설정이 SQL 과 같은 레포에서 함께 이동하므로
gitops 변경이나 별도 릴리스가 필요 없다.

```dockerfile
FROM flyway/flyway:11-alpine
# SQL 마이그레이션을 이미지에 내장한다. CI가 SHA 태그로 push하고
# gitops job.yaml의 이미지 태그를 교체하면 ArgoCD가 Job을 재실행한다.
COPY src/main/resources/db/migration /flyway/sql

# 시드 콘텐츠에 JS·Dart 템플릿 리터럴(${...})이 코드 예시로 들어 있다.
# Flyway 는 기본값에서 이를 placeholder 로 해석해 파싱에 실패하므로 치환을 끈다.
# 이 레포의 마이그레이션은 placeholder 를 쓰지 않는다(전수 확인: 0건).
ENV FLYWAY_PLACEHOLDER_REPLACEMENT=false
```

- [ ] **Step 5c: 테스트 하네스도 같은 설정을 쓰게 한다**

`FlywayMigrationTest` 는 36개 테스트가 각각 같은 2줄 체인으로 마이그레이션한다. 헬퍼로 묶고
그 자리에서 치환을 끈다. 운영과 테스트가 같은 Flyway 설정을 쓰게 하는 것이 목적이다.

파일의 `dataSource()` 메서드 바로 아래에 헬퍼를 추가한다.

```java
  /**
   * 모든 테스트가 같은 설정으로 마이그레이션한다.
   *
   * <p>placeholderReplacement 를 끈다: 시드 콘텐츠에 JS·Dart 템플릿 리터럴
   * ({@code ${response.status}}, {@code ${count}} 등)이 정상적인 코드 예시로 들어 있는데,
   * Flyway 는 기본값에서 이것을 치환 대상 placeholder 로 해석해 파싱에 실패한다.
   * 운영 이미지도 Dockerfile.migration 의 FLYWAY_PLACEHOLDER_REPLACEMENT=false 로
   * 같은 설정을 쓴다.
   */
  private static void migrate() {
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration")
        .placeholderReplacement(false)
        .load().migrate();
  }
```

36곳의 호출을 기계적으로 치환한다. 손으로 고치지 않는다.

```bash
perl -0pi -e 's/Flyway\.configure\(\)\.dataSource\(dataSource\(\)\)\s*\.locations\("classpath:db\/migration"\)\.load\(\)\.migrate\(\);/migrate();/g' \
  /d/workspace/dpa/devpath-shared/src/test/java/ai/devpath/shared/db/FlywayMigrationTest.java
```

치환 결과를 확인한다.

```bash
grep -c "Flyway.configure()" /d/workspace/dpa/devpath-shared/src/test/java/ai/devpath/shared/db/FlywayMigrationTest.java
grep -c "^    migrate();" /d/workspace/dpa/devpath-shared/src/test/java/ai/devpath/shared/db/FlywayMigrationTest.java
```

Expected: `Flyway.configure()` **1**건(헬퍼 안에만) · `migrate();` **36**건.

- [ ] **Step 6: 테스트가 green이 되는 것을 확인한다**

```bash
cd /d/workspace/dpa/devpath-shared && ./gradlew test --tests '*FlywayMigrationTest*'
```

Expected: PASS. Task 1의 세 테스트가 모두 통과한다.

> 실패하면 DB를 초기화하고 다시 돌린다: `docker compose down -v postgres && docker compose up -d postgres`.
> Flyway는 이미 적용된 마이그레이션을 다시 돌리지 않으므로, 마이그레이션을 고쳤다면 반드시 초기화해야 한다.

- [ ] **Step 7: 전체 스위트를 통과시킨다**

```bash
cd /d/workspace/dpa/devpath-shared && ./gradlew test
```

Expected: PASS (전체)

- [ ] **Step 8: 커밋**

```bash
git -C /d/workspace/dpa/devpath-shared add src/main/resources/db/migration/V202608131001__reseed_korean_seed_data.sql
git -C /d/workspace/dpa/devpath-shared commit -m "fix(seed): 운영 시드를 한국어 원본으로 교체한다

진단 문항 500개와 학습 콘텐츠 150개가 영어 더미로 적재돼 있었다.
문항은 선택지 1종을 500개가 공유하고 정답 인덱스만 무작위로 달라
풀 수 없는 문제였고, 폐기된 브랜드 DevPath 가 노출됐다.

한국어 원본은 이미 승인돼 learning-svc 클래스패스 시드로 쓰이고 있다.
그 본문을 그대로 옮긴다. 새로 생성한 콘텐츠는 없다.

옛 마이그레이션이 제외했던 RAG 임베딩 238건도 함께 적재해
콘텐츠 유사도 검색이 동작하게 한다.

무의미한 문항으로 산출된 진단 이력은 함께 삭제한다(전부 본인 테스트,
파생된 학습 경로 없음)."
```

---

### Task 3: PR 생성

**Files:** 없음(git 작업)

**Interfaces:**
- Consumes: Task 1·2의 커밋
- Produces: `develop` 대상 PR

- [ ] **Step 1: 커밋 범위를 직접 확인한다**

```bash
git -C /d/workspace/dpa/devpath-shared log --oneline origin/develop..HEAD
```

Expected: 3건 — 설계 문서(`f7385c5`) · 테스트 · 마이그레이션. 그 밖의 커밋이 있으면 멈추고 보고한다.

- [ ] **Step 2: 인접 레포에 낯선 변경이 생기지 않았는지 스팟체크한다**

```bash
git -C /d/workspace/dpa/devpath-learning-svc status -sb
git -C /d/workspace/dpa/devpath-frontend status -sb
```

Expected: 두 레포 모두 브랜치가 바뀌지 않았고 새 커밋이 없다. learning-svc의 시드 파일은 **읽기만** 했으므로 변경이 없어야 한다.

- [ ] **Step 3: 푸시하고 PR을 만든다**

```bash
git -C /d/workspace/dpa/devpath-shared push -u origin fix/reseed-korean-seed-data
cd /d/workspace/dpa/devpath-shared && gh pr create --base develop \
  --title "fix(seed): 운영 시드를 한국어 원본으로 교체한다" \
  --body "설계: docs/superpowers/specs/2026-08-13-reseed-korean-seed-data-design.md

운영 DB의 진단 문항 500개·학습 콘텐츠 150개가 영어 더미로 적재돼 있었다.
한국어 원본은 이미 승인돼 learning-svc 클래스패스 시드로 쓰이고 있었고,
운영 마이그레이션만 그 이전의 영어 파일에서 만들어졌다.

- 교체 마이그레이션 V202608131001 (가드 없이 삭제 후 재적재)
- RAG 임베딩 238건 함께 적재 (옛 마이그레이션이 제외했던 것)
- FlywayMigrationTest 에 품질 단언 추가 — 기존 단언은 개수만 봐서 이 사고를 놓쳤다

배포는 이 PR 머지 후 별도로 진행한다(shared develop→main 릴리스 → 마이그레이션 잡 수동 실행)."
```

- [ ] **Step 4: CI 결과를 직접 확인한다**

```bash
cd /d/workspace/dpa/devpath-shared && gh pr checks
```

Expected: `build` pass. 실패하면 로그를 읽고 원인을 규명한 뒤 보고한다. **머지하지 않는다** — 머지는 컨트롤러가 판단한다.

---

## 완료 조건

- `FlywayMigrationTest`의 세 품질 테스트가 통과한다.
- `./gradlew test` 전체가 통과한다.
- 마이그레이션 파일에 `IF (SELECT count` 가드가 없다.
- `DELETE FROM` 4건, `INSERT INTO content_embeddings` 238건이 파일에 있다.
- 기존 마이그레이션 파일이 수정되지 않았다.
- `develop` 대상 PR이 열려 있고 CI가 green이다.

## 이 계획의 범위 밖

배포(shared `develop`→`main` 릴리스 · 마이그레이션 잡 실행 · 운영 실측)는 컨트롤러가 별도로 수행한다.
진단 트랙 선택 하드코딩(②)과 베타 신청 스택 연결(③)은 별도 설계 대상이다.

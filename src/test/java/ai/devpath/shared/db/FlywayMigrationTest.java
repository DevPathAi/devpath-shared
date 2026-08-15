package ai.devpath.shared.db;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import javax.sql.DataSource;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.postgresql.ds.PGSimpleDataSource;

/**
 * 중앙 Flyway 마이그레이션 검증.
 * 로컬은 docker-compose의 postgres(5432), CI는 postgres service container에 연결한다.
 * 연결 정보는 DB_URL/DB_USER/DB_PASSWORD 환경변수로 주입한다 (기본은 로컬 compose).
 * 이미 적용된 DB에 대해서도 멱등하게 통과하도록 "결과 상태"(함수 존재)를 검증한다.
 */
class FlywayMigrationTest {

  private static DataSource dataSource() {
    PGSimpleDataSource ds = new PGSimpleDataSource();
    ds.setUrl(System.getenv().getOrDefault("DB_URL", "jdbc:postgresql://localhost:5432/devpath"));
    ds.setUser(System.getenv().getOrDefault("DB_USER", "devpath"));
    ds.setPassword(System.getenv().getOrDefault("DB_PASSWORD", "localdev"));
    return ds;
  }

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
    Flyway.configure()
        .configuration(java.util.Map.of("flyway.postgresql.transactional.lock", "false"))
        .dataSource(dataSource())
        .locations("classpath:db/migration")
        .placeholderReplacement(false)
        .load().migrate();
  }

  @Test
  void migrationsApplyAndCommonFunctionExists() throws Exception {
    migrate();
    try (var c = dataSource().getConnection();
        var st = c.createStatement();
        var rs = st.executeQuery("SELECT proname FROM pg_proc WHERE proname = 'set_updated_at'")) {
      assertTrue(rs.next(), "set_updated_at 함수가 존재해야 한다 (공통 규약 마이그레이션)");
    }
  }

  @Test
  void usersAndDormantArchivesExist() throws Exception {
    migrate();
    try (var c = dataSource().getConnection();
        var rs = c.getMetaData().getTables(null, "public", "%", new String[] {"TABLE"})) {
      var names = new java.util.HashSet<String>();
      while (rs.next()) names.add(rs.getString("TABLE_NAME"));
      assertTrue(names.contains("users"), "users 테이블 필요");
      assertTrue(names.contains("dormant_user_archives"), "dormant_user_archives 테이블 필요");
    }
  }

  private static java.util.Set<String> columns(String table) throws Exception {
    try (var c = dataSource().getConnection();
        var rs = c.getMetaData().getColumns(null, "public", table, "%")) {
      var cols = new java.util.HashSet<String>();
      while (rs.next()) cols.add(rs.getString("COLUMN_NAME"));
      return cols;
    }
  }

  @Test
  void usersHasAuthColumnsAndDropsGithubId() throws Exception {
    migrate();
    var cols = columns("users");
    assertTrue(cols.contains("email"), "users.email 필요");
    assertTrue(cols.contains("nickname"), "users.nickname 필요");
    assertTrue(cols.contains("role"), "users.role 필요");
    assertTrue(cols.contains("onboarding_status"), "users.onboarding_status 필요");
    assertFalse(cols.contains("github_id"), "users.github_id 제거(신원 이관)");
  }

  @Test
  void oauthIdentitiesTableExists() throws Exception {
    migrate();
    try (var c = dataSource().getConnection();
        var rs = c.getMetaData().getTables(null, "public", "user_oauth_identities", new String[] {"TABLE"})) {
      assertTrue(rs.next(), "user_oauth_identities 테이블 필요");
    }
  }

  @Test
  void userProfilesTableExists() throws Exception {
    migrate();
    try (var c = dataSource().getConnection();
        var rs = c.getMetaData().getTables(null, "public", "user_profiles", new String[] {"TABLE"})) {
      assertTrue(rs.next(), "user_profiles 테이블 필요");
    }
  }

  @Test
  void outboxTableExists() throws Exception {
    migrate();
    try (var c = dataSource().getConnection();
        var rs = c.getMetaData().getTables(null, "public", "outbox", new String[] {"TABLE"})) {
      assertTrue(rs.next(), "outbox 테이블 필요");
    }
  }

  @Test
  void notificationsTableExists() throws Exception {
    migrate();
    try (var c = dataSource().getConnection();
        var rs = c.getMetaData().getTables(null, "public", "notifications", new String[] {"TABLE"})) {
      assertTrue(rs.next(), "notifications 테이블 필요");
    }
  }

  @Test
  void questionBankTableExists() throws Exception {
    migrate();
    try (var c = dataSource().getConnection();
        var rs = c.getMetaData().getTables(null, "public", "question_bank", new String[] {"TABLE"})) {
      assertTrue(rs.next(), "question_bank 테이블 필요");
    }
  }

  @Test
  void assessmentsTableExists() throws Exception {
    migrate();
    try (var c = dataSource().getConnection();
        var rs = c.getMetaData().getTables(null, "public", "assessments", new String[] {"TABLE"})) {
      assertTrue(rs.next(), "assessments 테이블 필요");
    }
  }

  @Test
  void assessmentsSourceGuestIdContract() throws Exception {
    migrate();
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      try (var rs = st.executeQuery(
          "SELECT data_type, character_maximum_length, is_nullable "
              + "FROM information_schema.columns "
              + "WHERE table_schema = 'public' AND table_name = 'assessments' "
              + "AND column_name = 'source_guest_id'")) {
        assertTrue(rs.next(), "assessments.source_guest_id 컬럼 필요");
        assertEquals("character varying", rs.getString("data_type"));
        assertEquals(36, rs.getInt("character_maximum_length"));
        assertEquals("YES", rs.getString("is_nullable"));
        assertFalse(rs.next(), "source_guest_id 컬럼은 하나만 존재해야 한다");
      }
      try (var rs = st.executeQuery(
          "SELECT 1 FROM pg_constraint "
              + "WHERE conrelid = 'public.assessments'::regclass "
              + "AND conname = 'uq_assessments_source_guest_id' AND contype = 'u'")) {
        assertTrue(rs.next(), "source_guest_id DB UNIQUE constraint 필요");
      }

      c.setAutoCommit(false);
      try (var insert = c.prepareStatement(
          "INSERT INTO assessments(source_guest_id, track) VALUES (?, 'BACKEND_SPRING')")) {
        insert.setNull(1, java.sql.Types.VARCHAR);
        assertEquals(1, insert.executeUpdate());
        insert.setNull(1, java.sql.Types.VARCHAR);
        assertEquals(1, insert.executeUpdate(), "nullable UNIQUE는 NULL 여러 건을 허용해야 한다");

        var firstGuestId = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
        var secondGuestId = java.util.UUID.randomUUID().toString();
        insert.setString(1, firstGuestId);
        assertEquals(1, insert.executeUpdate());

        var duplicateSavepoint = c.setSavepoint();
        insert.setString(1, firstGuestId);
        var duplicate = assertThrows(java.sql.SQLException.class, insert::executeUpdate);
        assertEquals("23505", duplicate.getSQLState(), "동일 non-null guest ID는 unique violation이어야 한다");
        c.rollback(duplicateSavepoint);

        var nonCanonicalSavepoint = c.setSavepoint();
        insert.setString(1, firstGuestId.toUpperCase(java.util.Locale.ROOT));
        var nonCanonical = assertThrows(java.sql.SQLException.class, insert::executeUpdate);
        assertEquals("23514", nonCanonical.getSQLState(),
            "대소문자 변형으로 unique guest identity를 우회할 수 없어야 한다");
        c.rollback(nonCanonicalSavepoint);

        insert.setString(1, secondGuestId);
        assertEquals(1, insert.executeUpdate(), "서로 다른 guest ID는 공존해야 한다");

        var legacyGuestId = java.util.UUID.randomUUID().toString();
        Long legacyAssessmentId;
        try (var legacyInsert = c.prepareStatement(
            "INSERT INTO assessments(source_guest_id, track) "
                + "VALUES (NULL, 'BACKEND_SPRING') RETURNING id")) {
          try (var rs = legacyInsert.executeQuery()) {
            assertTrue(rs.next());
            legacyAssessmentId = rs.getLong(1);
          }
        }
        try (var bind = c.prepareStatement(
            "UPDATE assessments SET source_guest_id = ? WHERE id = ?")) {
          bind.setString(1, legacyGuestId);
          bind.setLong(2, legacyAssessmentId);
          assertEquals(1, bind.executeUpdate(), "legacy NULL row는 전환 중 한 번 귀속할 수 있어야 한다");

          var immutableSavepoint = c.setSavepoint();
          bind.setString(1, java.util.UUID.randomUUID().toString());
          var immutable = assertThrows(java.sql.SQLException.class, bind::executeUpdate);
          assertEquals("23514", immutable.getSQLState(), "귀속된 source_guest_id는 변경할 수 없어야 한다");
          c.rollback(immutableSavepoint);

          var nullRevertSavepoint = c.setSavepoint();
          bind.setNull(1, java.sql.Types.VARCHAR);
          var nullRevert = assertThrows(java.sql.SQLException.class, bind::executeUpdate);
          assertEquals("23514", nullRevert.getSQLState(),
              "귀속된 source_guest_id를 NULL로 되돌릴 수 없어야 한다");
          c.rollback(nullRevertSavepoint);
        }

        var invalidShapeSavepoint = c.setSavepoint();
        insert.setString(1, "not-a-guest-uuid");
        var invalidShape = assertThrows(java.sql.SQLException.class, insert::executeUpdate);
        assertEquals("23514", invalidShape.getSQLState(), "source_guest_id는 UUID 문자열 shape만 허용해야 한다");
        c.rollback(invalidShapeSavepoint);
      } finally {
        c.rollback();
      }
    }
  }

  @Test
  void assessmentItemsTableExists() throws Exception {
    migrate();
    try (var c = dataSource().getConnection();
        var rs = c.getMetaData().getTables(null, "public", "assessment_items", new String[] {"TABLE"})) {
      assertTrue(rs.next(), "assessment_items 테이블 필요");
    }
  }

  @Test
  void assessmentResultsTableExists() throws Exception {
    migrate();
    try (var c = dataSource().getConnection();
        var rs = c.getMetaData().getTables(null, "public", "assessment_results", new String[] {"TABLE"})) {
      assertTrue(rs.next(), "assessment_results 테이블 필요");
    }
  }

  @Test
  void questionBankRejectsBadEnumAndRange() throws Exception {
    migrate();
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      assertThrows(java.sql.SQLException.class, () ->
        st.execute("INSERT INTO question_bank(track,question_type,content,answer_key,bloom_level,difficulty) "
          + "VALUES ('BACKEND_SPRING','MCQ','q','{}','NOPE',0.3)"));
      assertThrows(java.sql.SQLException.class, () ->
        st.execute("INSERT INTO question_bank(track,question_type,content,answer_key,bloom_level,difficulty) "
          + "VALUES ('BACKEND_SPRING','MCQ','q','{}','APPLY',9.9)"));
    }
  }

  @Test
  void assessmentsHasNoUserFk() throws Exception {
    migrate();
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      // user_id 교차서비스 FK 제거(서비스 경계): 존재하지 않는 user_id로도 INSERT 가능해야 한다.
      st.execute("INSERT INTO assessments(user_id, track) VALUES (999999999, 'BACKEND_SPRING')");
      st.execute("DELETE FROM assessments WHERE user_id = 999999999");
    }
  }

  @Test
  void vectorExtensionAndPathTablesExist() throws Exception {
    migrate();
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      try (var rs = st.executeQuery("SELECT 1 FROM pg_extension WHERE extname = 'vector'")) {
        assertTrue(rs.next(), "vector 확장 필요");
      }
      for (String t : new String[] {"learning_paths", "path_milestones",
          "path_weekly_tasks", "contents", "content_embeddings"}) {
        try (var rs = c.getMetaData().getTables(null, "public", t, new String[] {"TABLE"})) {
          assertTrue(rs.next(), t + " 테이블 필요");
        }
      }
      try (var rs = st.executeQuery(
          "SELECT format_type(a.atttypid, a.atttypmod) "
              + "FROM pg_attribute a "
              + "JOIN pg_class c ON c.oid = a.attrelid "
              + "JOIN pg_namespace n ON n.oid = c.relnamespace "
              + "WHERE n.nspname = 'public' AND c.relname = 'content_embeddings' "
              + "AND a.attname = 'embedding' AND NOT a.attisdropped")) {
        assertTrue(rs.next(), "content_embeddings.embedding 컬럼 필요");
        assertTrue("vector(768)".equalsIgnoreCase(rs.getString(1)), "embedding은 VECTOR(768) 필요");
      }
      try (var rs = st.executeQuery(
          "SELECT 1 FROM pg_indexes "
              + "WHERE schemaname = 'public' "
              + "AND tablename = 'content_embeddings' "
              + "AND indexname = 'idx_content_embeddings_hnsw' "
              + "AND indexdef ILIKE '%USING hnsw%' "
              + "AND indexdef ILIKE '%vector_cosine_ops%' "
              + "AND indexdef ILIKE '%WHERE%' "
              + "AND indexdef ILIKE '%status%' "
              + "AND indexdef ILIKE '%ACTIVE%'")) {
        assertTrue(rs.next(), "ACTIVE 임베딩 HNSW cosine partial index 필요");
      }
    }
  }

  @Test
  void contentEmbeddingsCosineSmoke() throws Exception {
    migrate();
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      long cid;
      try (var rs = st.executeQuery("INSERT INTO contents(slug,title,track,content_md) "
          + "VALUES ('smoke-" + System.nanoTime() + "','t','BACKEND_SPRING','m') RETURNING id")) {
        assertTrue(rs.next(), "smoke content id 필요");
        cid = rs.getLong(1);
      }
      st.execute("INSERT INTO content_embeddings(content_id,chunk_index,chunk_text,embedding) "
          + "VALUES (" + cid + ",0,'c', array_fill(0.1::float8, ARRAY[768])::vector)");
      try (var rs = st.executeQuery(
          "SELECT embedding <=> array_fill(0.2::float8, ARRAY[768])::vector AS dist "
              + "FROM content_embeddings WHERE content_id=" + cid)) {
        assertTrue(rs.next(), "코사인 거리 쿼리 결과 필요");
        assertTrue(rs.getDouble("dist") >= 0.0, "코사인 거리는 0 이상이어야 한다");
      }
      st.execute("DELETE FROM content_embeddings WHERE content_id=" + cid);
      st.execute("DELETE FROM contents WHERE id=" + cid);
    }
  }

  @Test
  void learningPathsActiveUserUniqueEnforced() throws Exception {
    migrate();
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      long uid = System.nanoTime();
      st.execute("INSERT INTO learning_paths(user_id,track,status) VALUES (" + uid
          + ",'BACKEND_SPRING','ACTIVE')");
      assertThrows(java.sql.SQLException.class, () ->
          st.execute("INSERT INTO learning_paths(user_id,track,status) VALUES (" + uid
              + ",'BACKEND_SPRING','ACTIVE')"));
      st.execute("DELETE FROM learning_paths WHERE user_id=" + uid);
    }
  }

  @Test
  void userContentProgressTableContract() throws Exception {
    migrate();
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      try (var rs = c.getMetaData().getTables(null, "public", "user_content_progress",
          new String[] {"TABLE"})) {
        assertTrue(rs.next(), "user_content_progress 테이블 필요");
      }

      var cols = columns("user_content_progress");
      for (String col : new String[] {"id", "user_id", "content_id", "scroll_pct",
          "dwell_sec", "completed_at", "created_at", "updated_at"}) {
        assertTrue(cols.contains(col), "user_content_progress." + col + " 컬럼 필요");
      }

      try (var rs = st.executeQuery(
          "SELECT 1 FROM pg_constraint WHERE conname = 'uq_ucp_user_content'")) {
        assertTrue(rs.next(), "user_id + content_id unique constraint 필요");
      }
      try (var rs = st.executeQuery(
          "SELECT 1 FROM pg_constraint WHERE conname = 'chk_ucp_scroll'")) {
        assertTrue(rs.next(), "scroll_pct 범위 CHECK 필요");
      }
      try (var rs = st.executeQuery(
          "SELECT 1 FROM pg_constraint WHERE conname = 'chk_ucp_dwell'")) {
        assertTrue(rs.next(), "dwell_sec 비음수 CHECK 필요");
      }
      try (var rs = st.executeQuery(
          "SELECT 1 FROM pg_indexes WHERE schemaname = 'public' "
              + "AND tablename = 'user_content_progress' "
              + "AND indexname = 'idx_ucp_user_updated'")) {
        assertTrue(rs.next(), "user 최신 progress 조회 인덱스 필요");
      }
      try (var rs = st.executeQuery(
          "SELECT 1 FROM pg_indexes WHERE schemaname = 'public' "
              + "AND tablename = 'user_content_progress' "
              + "AND indexname = 'idx_ucp_content'")) {
        assertTrue(rs.next(), "content_id 인덱스 필요");
      }
    }
  }

  @Test
  void userContentProgressConstraintsAndCascadeWork() throws Exception {
    migrate();
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      long userId = System.nanoTime();
      long contentId;
      try (var rs = st.executeQuery("INSERT INTO contents(slug,title,track,content_md) "
          + "VALUES ('ucp-" + userId + "','t','BACKEND_SPRING','m') RETURNING id")) {
        assertTrue(rs.next(), "content id 필요");
        contentId = rs.getLong(1);
      }

      st.execute("INSERT INTO user_content_progress(user_id,content_id,scroll_pct,dwell_sec) "
          + "VALUES (" + userId + "," + contentId + ",0.4,10)");

      assertThrows(java.sql.SQLException.class, () ->
          st.execute("INSERT INTO user_content_progress(user_id,content_id,scroll_pct,dwell_sec) "
              + "VALUES (" + userId + "," + contentId + ",0.5,11)"));
      assertThrows(java.sql.SQLException.class, () ->
          st.execute("INSERT INTO user_content_progress(user_id,content_id,scroll_pct,dwell_sec) "
              + "VALUES (" + (userId + 1) + "," + contentId + ",-0.1,10)"));
      assertThrows(java.sql.SQLException.class, () ->
          st.execute("INSERT INTO user_content_progress(user_id,content_id,scroll_pct,dwell_sec) "
              + "VALUES (" + (userId + 2) + "," + contentId + ",1.1,10)"));
      assertThrows(java.sql.SQLException.class, () ->
          st.execute("INSERT INTO user_content_progress(user_id,content_id,scroll_pct,dwell_sec) "
              + "VALUES (" + (userId + 3) + "," + contentId + ",0.2,-1)"));

      st.execute("DELETE FROM contents WHERE id = " + contentId);
      try (var rs = st.executeQuery(
          "SELECT count(*) FROM user_content_progress WHERE user_id = " + userId)) {
        assertTrue(rs.next(), "count 결과 필요");
        assertTrue(rs.getLong(1) == 0L, "content 삭제 시 progress도 cascade 삭제되어야 한다");
      }
    }
  }

  @Test
  void userContentProgressHasNoUserForeignKeyAndUpdatedAtTrigger() throws Exception {
    migrate();
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      long userId = 999_999_000L + (System.nanoTime() % 100_000L);
      long contentId;
      long progressId;
      try (var rs = st.executeQuery("INSERT INTO contents(slug,title,track,content_md) "
          + "VALUES ('ucp-trigger-" + userId + "','t','BACKEND_SPRING','m') RETURNING id")) {
        assertTrue(rs.next(), "content id 필요");
        contentId = rs.getLong(1);
      }

      // user_id는 platform users 논리 참조다. users FK가 없어야 이 INSERT가 통과한다.
      try (var rs = st.executeQuery(
          "INSERT INTO user_content_progress(user_id,content_id) VALUES ("
              + userId + "," + contentId + ") RETURNING id")) {
        assertTrue(rs.next(), "progress id 필요");
        progressId = rs.getLong(1);
      }

      st.execute("UPDATE user_content_progress "
          + "SET updated_at = TIMESTAMPTZ '2000-01-01 00:00:00+00', dwell_sec = 1 "
          + "WHERE id = " + progressId);
      try (var rs = st.executeQuery(
          "SELECT updated_at > TIMESTAMPTZ '2020-01-01 00:00:00+00' "
              + "FROM user_content_progress WHERE id = " + progressId)) {
        assertTrue(rs.next(), "updated_at 결과 필요");
        assertTrue(rs.getBoolean(1), "updated_at trigger가 now()로 갱신되어야 한다");
      }

      st.execute("DELETE FROM contents WHERE id = " + contentId);
    }
  }

  @Test
  void sandboxSessionsTableContract() throws Exception {
    migrate();
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      try (var rs = c.getMetaData().getTables(null, "public", "sandbox_sessions",
          new String[] {"TABLE"})) {
        assertTrue(rs.next(), "sandbox_sessions 테이블 필요");
      }
      var cols = columns("sandbox_sessions");
      for (String col : new String[] {"id", "user_id", "content_id", "code_block_id",
          "language", "container_id", "status", "submitted_code", "stdout", "stderr",
          "exit_code", "cpu_ms_used", "memory_mb_peak", "output_truncated", "started_at",
          "finished_at", "created_at", "updated_at"}) {
        assertTrue(cols.contains(col), "sandbox_sessions." + col + " 컬럼 필요");
      }

      assertThrows(java.sql.SQLException.class, () ->
          st.execute("INSERT INTO sandbox_sessions(user_id,language,submitted_code) "
              + "VALUES (1,'RUBY','x')"));
      assertThrows(java.sql.SQLException.class, () ->
          st.execute("INSERT INTO sandbox_sessions(user_id,language,status,submitted_code) "
              + "VALUES (1,'PYTHON','BOGUS','x')"));
      try (var rs = st.executeQuery(
          "SELECT 1 FROM pg_indexes WHERE schemaname = 'public' "
              + "AND tablename = 'sandbox_sessions' "
              + "AND indexname = 'idx_sandbox_user_started'")) {
        assertTrue(rs.next(), "user 실습이력 인덱스 필요");
      }
    }
  }

  @Test
  void sandboxSessionsHasNoUserFkAndUpdatedAtTrigger() throws Exception {
    migrate();
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      long userId = 999_999_000L + (System.nanoTime() % 100_000L);
      long sid;
      // user_id는 platform users 논리 참조다. users FK가 없어야 이 INSERT가 통과한다.
      try (var rs = st.executeQuery(
          "INSERT INTO sandbox_sessions(user_id,language,submitted_code) "
              + "VALUES (" + userId + ",'PYTHON','print(1)') RETURNING id")) {
        assertTrue(rs.next(), "sandbox_session id 필요");
        sid = rs.getLong(1);
      }
      st.execute("UPDATE sandbox_sessions "
          + "SET updated_at = TIMESTAMPTZ '2000-01-01 00:00:00+00', status = 'RUNNING' "
          + "WHERE id = " + sid);
      try (var rs = st.executeQuery(
          "SELECT updated_at > TIMESTAMPTZ '2020-01-01 00:00:00+00' "
              + "FROM sandbox_sessions WHERE id = " + sid)) {
        assertTrue(rs.next(), "updated_at 결과 필요");
        assertTrue(rs.getBoolean(1), "updated_at trigger가 now()로 갱신되어야 한다");
      }
      st.execute("DELETE FROM sandbox_sessions WHERE id = " + sid);
    }
  }

  @Test
  void aiCodeReviewsTableContract() throws Exception {
    migrate();
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      try (var rs = c.getMetaData().getTables(null, "public", "ai_code_reviews",
          new String[] {"TABLE"})) {
        assertTrue(rs.next(), "ai_code_reviews 테이블 필요");
      }
      var cols = columns("ai_code_reviews");
      for (String col : new String[] {"id", "sandbox_session_id", "user_id", "content_id",
          "status", "provider", "confidence", "strengths", "improvements", "security",
          "feedback", "error_code", "created_at", "updated_at"}) {
        assertTrue(cols.contains(col), "ai_code_reviews." + col + " 컬럼 필요");
      }

      // status CHECK
      assertThrows(java.sql.SQLException.class, () ->
          st.execute("INSERT INTO ai_code_reviews(sandbox_session_id,user_id,status) "
              + "VALUES (1,1,'BOGUS')"));
      // feedback CHECK
      assertThrows(java.sql.SQLException.class, () ->
          st.execute("INSERT INTO ai_code_reviews(sandbox_session_id,user_id,feedback) "
              + "VALUES (1,1,'MAYBE')"));
      // confidence 범위 CHECK
      assertThrows(java.sql.SQLException.class, () ->
          st.execute("INSERT INTO ai_code_reviews(sandbox_session_id,user_id,confidence) "
              + "VALUES (1,1,200)"));

      // UNIQUE(sandbox_session_id)
      long sid = System.nanoTime();
      st.execute("INSERT INTO ai_code_reviews(sandbox_session_id,user_id) VALUES ("
          + sid + ",1)");
      assertThrows(java.sql.SQLException.class, () ->
          st.execute("INSERT INTO ai_code_reviews(sandbox_session_id,user_id) VALUES ("
              + sid + ",2)"));
      st.execute("DELETE FROM ai_code_reviews WHERE sandbox_session_id = " + sid);

      try (var rs = st.executeQuery(
          "SELECT 1 FROM pg_indexes WHERE schemaname = 'public' "
              + "AND tablename = 'ai_code_reviews' "
              + "AND indexname = 'idx_ai_reviews_user_created'")) {
        assertTrue(rs.next(), "user 최신 리뷰 조회 인덱스 필요");
      }
    }
  }

  @Test
  void aiCodeReviewsNoUserFkAndUpdatedAtTrigger() throws Exception {
    migrate();
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      long userId = 999_999_000L + (System.nanoTime() % 100_000L);
      long reviewId;
      // user_id/sandbox_session_id는 논리 참조다. FK가 없어야 존재하지 않는 id로도 INSERT가 통과한다.
      try (var rs = st.executeQuery(
          "INSERT INTO ai_code_reviews(sandbox_session_id,user_id,status) "
              + "VALUES (" + userId + "," + userId + ",'PENDING') RETURNING id")) {
        assertTrue(rs.next(), "ai_code_reviews id 필요");
        reviewId = rs.getLong(1);
      }
      st.execute("UPDATE ai_code_reviews "
          + "SET updated_at = TIMESTAMPTZ '2000-01-01 00:00:00+00', status = 'DONE' "
          + "WHERE id = " + reviewId);
      try (var rs = st.executeQuery(
          "SELECT updated_at > TIMESTAMPTZ '2020-01-01 00:00:00+00' "
              + "FROM ai_code_reviews WHERE id = " + reviewId)) {
        assertTrue(rs.next(), "updated_at 결과 필요");
        assertTrue(rs.getBoolean(1), "updated_at trigger가 now()로 갱신되어야 한다");
      }
      st.execute("DELETE FROM ai_code_reviews WHERE id = " + reviewId);
    }
  }

  @Test
  void aiMentorSessionsTableContract() throws Exception {
    migrate();
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      try (var rs = c.getMetaData().getTables(null, "public", "ai_mentor_sessions",
          new String[] {"TABLE"})) {
        assertTrue(rs.next(), "ai_mentor_sessions 테이블 필요");
      }
      var cols = columns("ai_mentor_sessions");
      for (String col : new String[] {"id", "user_id", "content_id", "question", "answer",
          "context_snapshot", "reference_links", "provider", "status", "error_code",
          "created_at", "updated_at"}) {
        assertTrue(cols.contains(col), "ai_mentor_sessions." + col + " 컬럼 필요");
      }

      // status CHECK (DONE/FAILED만 — PENDING 없음, M-6)
      assertThrows(java.sql.SQLException.class, () ->
          st.execute("INSERT INTO ai_mentor_sessions(user_id,question,status) "
              + "VALUES (1,'q','PENDING')"));
      assertThrows(java.sql.SQLException.class, () ->
          st.execute("INSERT INTO ai_mentor_sessions(user_id,question,status) "
              + "VALUES (1,'q','BOGUS')"));

      // 단발(UNIQUE 없음): 같은 user로 2건 INSERT 통과
      long uid = System.nanoTime();
      st.execute("INSERT INTO ai_mentor_sessions(user_id,question,status) VALUES ("
          + uid + ",'q1','DONE')");
      st.execute("INSERT INTO ai_mentor_sessions(user_id,question,status) VALUES ("
          + uid + ",'q2','DONE')");
      try (var rs = st.executeQuery(
          "SELECT count(*) FROM ai_mentor_sessions WHERE user_id = " + uid)) {
        assertTrue(rs.next());
        assertTrue(rs.getInt(1) == 2, "단발이라 동일 user 다건 허용(UNIQUE 없음)");
      }
      st.execute("DELETE FROM ai_mentor_sessions WHERE user_id = " + uid);

      try (var rs = st.executeQuery(
          "SELECT 1 FROM pg_indexes WHERE schemaname = 'public' "
              + "AND tablename = 'ai_mentor_sessions' "
              + "AND indexname = 'idx_ai_mentor_user_created'")) {
        assertTrue(rs.next(), "user 최신 멘토 이력 조회 인덱스 필요");
      }
    }
  }

  @Test
  void aiMentorSessionsNoUserFkAndUpdatedAtTrigger() throws Exception {
    migrate();
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      long userId = 999_999_000L + (System.nanoTime() % 100_000L);
      long sessionId;
      // user_id/content_id는 논리 참조다. FK가 없어야 존재하지 않는 id로도 INSERT가 통과한다.
      try (var rs = st.executeQuery(
          "INSERT INTO ai_mentor_sessions(user_id,content_id,question,status) "
              + "VALUES (" + userId + "," + userId + ",'q','DONE') RETURNING id")) {
        assertTrue(rs.next(), "ai_mentor_sessions id 필요");
        sessionId = rs.getLong(1);
      }
      st.execute("UPDATE ai_mentor_sessions "
          + "SET updated_at = TIMESTAMPTZ '2000-01-01 00:00:00+00', answer = 'a' "
          + "WHERE id = " + sessionId);
      try (var rs = st.executeQuery(
          "SELECT updated_at > TIMESTAMPTZ '2020-01-01 00:00:00+00' "
              + "FROM ai_mentor_sessions WHERE id = " + sessionId)) {
        assertTrue(rs.next(), "updated_at 결과 필요");
        assertTrue(rs.getBoolean(1), "updated_at trigger가 now()로 갱신되어야 한다");
      }
      st.execute("DELETE FROM ai_mentor_sessions WHERE id = " + sessionId);
    }
  }

  @Test
  void communityPostsTableContract() throws Exception {
    migrate();
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      var cols = columns("community_posts");
      for (String col : new String[] {"id", "author_id", "board_type", "title", "body_md",
          "body_html", "status", "view_count", "upvote_count", "downvote_count",
          "created_at", "updated_at"}) {
        assertTrue(cols.contains(col), "community_posts." + col + " 컬럼 필요");
      }
      // board_type CHECK
      assertThrows(java.sql.SQLException.class, () ->
          st.execute("INSERT INTO community_posts(author_id,board_type,title,body_md) "
              + "VALUES (1,'BOGUS','t','b')"));
      // status CHECK
      assertThrows(java.sql.SQLException.class, () ->
          st.execute("INSERT INTO community_posts(author_id,board_type,title,body_md,status) "
              + "VALUES (1,'QNA','t','b','NOPE')"));
      try (var rs = st.executeQuery(
          "SELECT 1 FROM pg_indexes WHERE schemaname='public' "
              + "AND tablename='community_posts' "
              + "AND indexname='idx_community_posts_board_status_created'")) {
        assertTrue(rs.next(), "게시판별 최신글 인덱스 필요");
      }
    }
  }

  @Test
  void communityQnaTablesAndVotesContract() throws Exception {
    migrate();
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      for (String t : new String[] {"community_questions", "community_answers",
          "community_votes", "community_tags", "community_post_tags", "community_ai_answers"}) {
        try (var rs = c.getMetaData().getTables(null, "public", t, new String[] {"TABLE"})) {
          assertTrue(rs.next(), t + " 테이블 필요");
        }
      }
      // votes: value CHECK + target CHECK + UNIQUE(user_id,target_type,target_id)
      assertThrows(java.sql.SQLException.class, () ->
          st.execute("INSERT INTO community_votes(user_id,target_type,target_id,value) "
              + "VALUES (1,'POST',1,2)"));
      assertThrows(java.sql.SQLException.class, () ->
          st.execute("INSERT INTO community_votes(user_id,target_type,target_id,value) "
              + "VALUES (1,'BOGUS',1,1)"));
      long uid = System.nanoTime();
      st.execute("INSERT INTO community_votes(user_id,target_type,target_id,value) "
          + "VALUES (" + uid + ",'POST',1,1)");
      assertThrows(java.sql.SQLException.class, () ->
          st.execute("INSERT INTO community_votes(user_id,target_type,target_id,value) "
              + "VALUES (" + uid + ",'POST',1,-1)"));
      st.execute("DELETE FROM community_votes WHERE user_id=" + uid);
    }
  }

  @Test
  void communityQuestionEmbeddingVectorAndAiAnswerIdempotency() throws Exception {
    migrate();
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      // question_embedding은 VECTOR(768)
      try (var rs = st.executeQuery(
          "SELECT format_type(a.atttypid, a.atttypmod) FROM pg_attribute a "
              + "JOIN pg_class cl ON cl.oid = a.attrelid "
              + "JOIN pg_namespace n ON n.oid = cl.relnamespace "
              + "WHERE n.nspname='public' AND cl.relname='community_questions' "
              + "AND a.attname='question_embedding' AND NOT a.attisdropped")) {
        assertTrue(rs.next(), "question_embedding 컬럼 필요");
        assertTrue("vector(768)".equalsIgnoreCase(rs.getString(1)), "question_embedding은 VECTOR(768)");
      }
      // valid question 선행(FK 충족)으로 status CHECK와 PK 멱등을 정확히 분리 검증
      long pid;
      try (var rs = st.executeQuery("INSERT INTO community_posts(author_id,board_type,title,body_md) "
          + "VALUES (1,'QNA','t','b') RETURNING id")) {
        assertTrue(rs.next()); pid = rs.getLong(1);
      }
      st.execute("INSERT INTO community_questions(post_id) VALUES (" + pid + ")");
      // status CHECK: PENDING 거부(valid FK라 FK 위반이 아닌 CHECK 위반)
      assertThrows(java.sql.SQLException.class, () ->
          st.execute("INSERT INTO community_ai_answers(question_id,status) VALUES (" + pid + ",'PENDING')"));
      // PK(question_id) 멱등: 같은 question_id 중복 거부
      st.execute("INSERT INTO community_ai_answers(question_id,status) VALUES (" + pid + ",'DONE')");
      assertThrows(java.sql.SQLException.class, () ->
          st.execute("INSERT INTO community_ai_answers(question_id,status) VALUES (" + pid + ",'DONE')"));
      st.execute("DELETE FROM community_posts WHERE id=" + pid); // cascade questions/ai_answers
    }
  }

  @Test
  void communityNoAuthorFkAndUpdatedAtTrigger() throws Exception {
    migrate();
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      long authorId = 999_999_000L + (System.nanoTime() % 100_000L);
      long pid;
      // author_id는 platform users 논리 참조다. FK가 없어야 존재하지 않는 id로도 INSERT가 통과한다.
      try (var rs = st.executeQuery("INSERT INTO community_posts(author_id,board_type,title,body_md) "
          + "VALUES (" + authorId + ",'QNA','t','b') RETURNING id")) {
        assertTrue(rs.next()); pid = rs.getLong(1);
      }
      st.execute("UPDATE community_posts SET updated_at = TIMESTAMPTZ '2000-01-01 00:00:00+00', "
          + "view_count = 1 WHERE id = " + pid);
      try (var rs = st.executeQuery(
          "SELECT updated_at > TIMESTAMPTZ '2020-01-01 00:00:00+00' "
              + "FROM community_posts WHERE id = " + pid)) {
        assertTrue(rs.next());
        assertTrue(rs.getBoolean(1), "updated_at trigger가 now()로 갱신되어야 한다");
      }
      st.execute("DELETE FROM community_posts WHERE id = " + pid);
    }
  }

  @Test
  void questionBankSeeded() throws Exception {
    migrate();
    try (var c = dataSource().getConnection(); var st = c.createStatement();
        var rs = st.executeQuery("SELECT count(*) FROM question_bank")) {
      assertTrue(rs.next(), "count 결과 필요");
      assertTrue(rs.getLong(1) >= 500, "question_bank는 500문항 이상 시드되어야 한다");
    }
  }

  @Test
  void contentsSeeded() throws Exception {
    migrate();
    try (var c = dataSource().getConnection(); var st = c.createStatement();
        var rs = st.executeQuery("SELECT count(*) FROM contents")) {
      assertTrue(rs.next(), "count 결과 필요");
      assertTrue(rs.getLong(1) >= 150, "contents는 150개 이상 시드되어야 한다");
    }
  }

  /**
   * 광고 슬롯별 소스 설정 시드. 슬롯 3개가 정확히 존재하는지만 본다.
   *
   * <p>source·adsense_slot_id의 현재 값은 단언하지 않는다 — 이 DB는 platform-svc
   * 테스트와 공유되고 그쪽이 슬롯 설정을 바꾸므로, 값을 고정으로 보면 실행 순서에
   * 따라 깨진다. 이 파일의 방침대로 "이미 적용된 DB에서도 멱등하게 통과하는
   * 결과 상태"를 검증한다.
   */
  @Test
  void adSlotConfigSeedsThreeSlots() throws Exception {
    migrate();
    try (var c = dataSource().getConnection(); var st = c.createStatement();
        var rs = st.executeQuery("SELECT slot FROM ad_slot_config ORDER BY slot")) {
      var slots = new java.util.ArrayList<String>();
      while (rs.next()) slots.add(rs.getString("slot"));
      assertTrue(
          slots.equals(java.util.List.of("COMMUNITY_FEED", "CONTENT_PAGE", "DASHBOARD_TOP")),
          "슬롯 3행이 시드되어야 한다 (실제: " + slots + ")");
    }
  }

  /** 슬롯·소스 CHECK 제약이 카탈로그 밖의 값을 막아야 한다. */
  @Test
  void adSlotConfigRejectsUnknownSlotAndSource() throws Exception {
    migrate();
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      assertThrows(java.sql.SQLException.class, () ->
          st.execute("INSERT INTO ad_slot_config(slot,source) VALUES ('SIDEBAR','HOUSE')"));
      assertThrows(java.sql.SQLException.class, () ->
          st.execute("INSERT INTO ad_slot_config(slot,source) VALUES ('DASHBOARD_TOP','BANNERFLOW')"));
    }
  }

  /**
   * 시드 문항의 품질. 개수만 보던 questionBankSeeded()가 놓친 것을 잡는다.
   *
   * <p>2026-08-13 사고: 운영에 적재된 500문항이 전부 같은 영어 템플릿이었고
   * 선택지 4개가 500문항에서 동일했다(정답 인덱스만 무작위). 개수 단언은 통과했다.
   */
  @Test
  void questionBankSeedIsKorean() throws Exception {
    migrate();
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
    migrate();
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
    migrate();
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      try (var rs = st.executeQuery(
          "SELECT count(*) AS total, count(DISTINCT embedding::text) AS distinct_vec"
              + " FROM content_embeddings")) {
        assertTrue(rs.next(), "집계 결과 필요");
        long total = rs.getLong("total");
        assertTrue(total >= 238, "임베딩은 238건 이상 시드되어야 한다 (실제: " + total + ")");
        // 모든 행이 같은 벡터면 유사도 검색이 무의미해진다.
        // contentEmbeddingsCosineSmoke 가 남길 수 있는 픽스처 1행을 감안해 >= 로 둔다.
        assertTrue(rs.getLong("distinct_vec") >= 238,
            "서로 다른 임베딩 벡터가 238개 이상이어야 한다 (서로 다른 값: "
                + rs.getLong("distinct_vec") + " / " + total + ")");
      }
      // slug 가 어긋나면 에러 없이 0행이 들어간다. 임베딩이 붙은 콘텐츠 수도 함께 본다.
      try (var rs2 = st.executeQuery(
          "SELECT count(DISTINCT content_id) AS covered FROM content_embeddings")) {
        assertTrue(rs2.next(), "집계 결과 필요");
        assertTrue(rs2.getLong("covered") >= 100,
            "임베딩이 붙은 콘텐츠가 100개 이상이어야 한다 (실제: " + rs2.getLong("covered") + ")");
      }
    }
  }

  /**
   * 소비 서비스 경로 회귀 가드.
   *
   * <p>shared 의 마이그레이션 SQL 은 jar 에 실려 서비스 레포 테스트에서
   * spring.flyway 기본 설정(placeholder-replacement=true)으로 실행된다.
   * Dockerfile.migration·build.gradle.kts·이 파일의 migrate() 헬퍼는 그 경로에 닿지 않는다.
   * 시드 콘텐츠의 ${...}(JS·Dart 템플릿 리터럴)를 견디는 것은 마이그레이션 옆의
   * 스크립트 설정 파일뿐이다. 그 파일이 사라지거나, 새 마이그레이션이 ${...} 를
   * 스크립트 설정 없이 들여오면 이 테스트가 red 가 된다.
   */
  @Test
  void migrationsWithPlaceholderSyntaxCarryScriptConfig() throws Exception {
    var dir = java.nio.file.Path.of("src/main/resources/db/migration");
    try (var paths = java.nio.file.Files.list(dir)) {
      for (var sql : paths.filter(p -> p.toString().endsWith(".sql")).toList()) {
        String body = java.nio.file.Files.readString(sql, java.nio.charset.StandardCharsets.UTF_8);
        if (!body.contains("${")) {
          continue;
        }
        var conf = sql.resolveSibling(sql.getFileName() + ".conf");
        assertTrue(java.nio.file.Files.exists(conf),
            sql.getFileName() + " 는 ${...} 를 담고 있으므로 " + conf.getFileName() + " 가 필요하다");
        String withoutFlywayBuiltIns = body.replaceAll("\\$\\{flyway:[^}]+}", "");
        boolean needsApplicationLiteralProtection = withoutFlywayBuiltIns.contains("${");
        String config = java.nio.file.Files.readString(
            conf, java.nio.charset.StandardCharsets.UTF_8);
        assertTrue(
            config.contains(needsApplicationLiteralProtection
                ? "placeholderReplacement=false"
                : "placeholderReplacement=true"),
            conf.getFileName() + " 의 placeholder mode가 SQL placeholder 종류와 일치해야 한다");
      }
    }
  }
}

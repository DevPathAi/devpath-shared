package ai.devpath.shared.db;

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

  @Test
  void migrationsApplyAndCommonFunctionExists() throws Exception {
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
    try (var c = dataSource().getConnection();
        var st = c.createStatement();
        var rs = st.executeQuery("SELECT proname FROM pg_proc WHERE proname = 'set_updated_at'")) {
      assertTrue(rs.next(), "set_updated_at 함수가 존재해야 한다 (공통 규약 마이그레이션)");
    }
  }

  @Test
  void usersAndDormantArchivesExist() throws Exception {
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
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
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
    var cols = columns("users");
    assertTrue(cols.contains("email"), "users.email 필요");
    assertTrue(cols.contains("nickname"), "users.nickname 필요");
    assertTrue(cols.contains("role"), "users.role 필요");
    assertTrue(cols.contains("onboarding_status"), "users.onboarding_status 필요");
    assertFalse(cols.contains("github_id"), "users.github_id 제거(신원 이관)");
  }

  @Test
  void oauthIdentitiesTableExists() throws Exception {
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
    try (var c = dataSource().getConnection();
        var rs = c.getMetaData().getTables(null, "public", "user_oauth_identities", new String[] {"TABLE"})) {
      assertTrue(rs.next(), "user_oauth_identities 테이블 필요");
    }
  }

  @Test
  void userProfilesTableExists() throws Exception {
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
    try (var c = dataSource().getConnection();
        var rs = c.getMetaData().getTables(null, "public", "user_profiles", new String[] {"TABLE"})) {
      assertTrue(rs.next(), "user_profiles 테이블 필요");
    }
  }

  @Test
  void outboxTableExists() throws Exception {
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
    try (var c = dataSource().getConnection();
        var rs = c.getMetaData().getTables(null, "public", "outbox", new String[] {"TABLE"})) {
      assertTrue(rs.next(), "outbox 테이블 필요");
    }
  }

  @Test
  void notificationsTableExists() throws Exception {
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
    try (var c = dataSource().getConnection();
        var rs = c.getMetaData().getTables(null, "public", "notifications", new String[] {"TABLE"})) {
      assertTrue(rs.next(), "notifications 테이블 필요");
    }
  }

  @Test
  void questionBankTableExists() throws Exception {
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
    try (var c = dataSource().getConnection();
        var rs = c.getMetaData().getTables(null, "public", "question_bank", new String[] {"TABLE"})) {
      assertTrue(rs.next(), "question_bank 테이블 필요");
    }
  }

  @Test
  void assessmentsTableExists() throws Exception {
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
    try (var c = dataSource().getConnection();
        var rs = c.getMetaData().getTables(null, "public", "assessments", new String[] {"TABLE"})) {
      assertTrue(rs.next(), "assessments 테이블 필요");
    }
  }

  @Test
  void assessmentItemsTableExists() throws Exception {
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
    try (var c = dataSource().getConnection();
        var rs = c.getMetaData().getTables(null, "public", "assessment_items", new String[] {"TABLE"})) {
      assertTrue(rs.next(), "assessment_items 테이블 필요");
    }
  }

  @Test
  void assessmentResultsTableExists() throws Exception {
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
    try (var c = dataSource().getConnection();
        var rs = c.getMetaData().getTables(null, "public", "assessment_results", new String[] {"TABLE"})) {
      assertTrue(rs.next(), "assessment_results 테이블 필요");
    }
  }

  @Test
  void questionBankRejectsBadEnumAndRange() throws Exception {
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
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
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
    try (var c = dataSource().getConnection(); var st = c.createStatement()) {
      // user_id 교차서비스 FK 제거(서비스 경계): 존재하지 않는 user_id로도 INSERT 가능해야 한다.
      st.execute("INSERT INTO assessments(user_id, track) VALUES (999999999, 'BACKEND_SPRING')");
      st.execute("DELETE FROM assessments WHERE user_id = 999999999");
    }
  }

  @Test
  void vectorExtensionAndPathTablesExist() throws Exception {
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
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
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
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
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
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
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
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
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
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
    Flyway.configure().dataSource(dataSource())
        .locations("classpath:db/migration").load().migrate();
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
}

-- Slice #3: learning path, content, and embedding schema. pgvector 768 dimensions.
-- user_id is a logical platform users reference only; no cross-service FK.
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE learning_paths (
  id                       BIGSERIAL PRIMARY KEY,
  user_id                  BIGINT NOT NULL,
  generated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
  track                    VARCHAR(20) NOT NULL,
  total_weeks              INT NOT NULL DEFAULT 12,
  gen_prompt_version       VARCHAR(20),
  source_embedding_version VARCHAR(40),
  status                   VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  ai_rationale             TEXT,
  CONSTRAINT chk_lp_track CHECK (track IN ('BACKEND_SPRING','FRONTEND_REACT','MOBILE_FLUTTER','DEVOPS','FULLSTACK')),
  CONSTRAINT chk_lp_status CHECK (status IN ('ACTIVE','ARCHIVED'))
);

CREATE UNIQUE INDEX uq_learning_paths_active_user ON learning_paths(user_id) WHERE status = 'ACTIVE';
CREATE INDEX idx_learning_paths_user ON learning_paths(user_id);

CREATE TABLE contents (
  id                BIGSERIAL PRIMARY KEY,
  slug              VARCHAR(120) NOT NULL UNIQUE,
  title             VARCHAR(300) NOT NULL,
  track             VARCHAR(20) NOT NULL,
  content_md        TEXT NOT NULL,
  estimated_minutes INT,
  difficulty        DOUBLE PRECISION,
  bloom_level       VARCHAR(20),
  concept_tags      JSONB,
  status            VARCHAR(20) NOT NULL DEFAULT 'PUBLISHED',
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_contents_track CHECK (track IN ('BACKEND_SPRING','FRONTEND_REACT','MOBILE_FLUTTER','DEVOPS','FULLSTACK')),
  CONSTRAINT chk_contents_status CHECK (status IN ('DRAFT','PUBLISHED'))
);

CREATE INDEX idx_contents_track_status_diff ON contents(track, status, difficulty);
CREATE TRIGGER contents_set_updated_at BEFORE UPDATE ON contents
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE path_milestones (
  id               BIGSERIAL PRIMARY KEY,
  path_id          BIGINT NOT NULL REFERENCES learning_paths(id) ON DELETE CASCADE,
  week_num         INT NOT NULL,
  title            VARCHAR(200) NOT NULL,
  goal_description TEXT,
  target_skills    JSONB,
  estimated_hours  INT,
  why_this_order   TEXT,
  expected_outcome TEXT,
  CONSTRAINT uq_path_milestones_week UNIQUE (path_id, week_num),
  CONSTRAINT chk_pm_week CHECK (week_num > 0)
);

CREATE TABLE path_weekly_tasks (
  id           BIGSERIAL PRIMARY KEY,
  milestone_id BIGINT NOT NULL REFERENCES path_milestones(id) ON DELETE CASCADE,
  order_num    INT NOT NULL,
  content_id   BIGINT REFERENCES contents(id),
  task_type    VARCHAR(20) NOT NULL,
  title        VARCHAR(300) NOT NULL,
  required     BOOLEAN NOT NULL DEFAULT TRUE,
  completed_at TIMESTAMPTZ,
  CONSTRAINT uq_path_weekly_tasks_order UNIQUE (milestone_id, order_num),
  CONSTRAINT chk_pwt_order CHECK (order_num > 0),
  CONSTRAINT chk_pwt_task_type CHECK (task_type IN ('READ','PRACTICE','QUIZ'))
);

CREATE INDEX idx_path_weekly_tasks_milestone ON path_weekly_tasks(milestone_id);

CREATE TABLE content_embeddings (
  id          BIGSERIAL PRIMARY KEY,
  content_id  BIGINT NOT NULL REFERENCES contents(id) ON DELETE CASCADE,
  chunk_index INT NOT NULL,
  chunk_text  TEXT NOT NULL,
  embedding   VECTOR(768) NOT NULL,
  chunk_hash  VARCHAR(64),
  status      VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  CONSTRAINT chk_ce_status CHECK (status IN ('ACTIVE','INACTIVE'))
);

CREATE INDEX idx_content_embeddings_hnsw ON content_embeddings
  USING hnsw (embedding vector_cosine_ops) WHERE status = 'ACTIVE';

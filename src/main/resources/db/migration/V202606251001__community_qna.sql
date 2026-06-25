-- MD3 Slice #8: community Q&A (posts, questions, answers, votes, tags, ai seed answers).
-- author_id = platform users logical reference only; NO cross-service FK.
-- Intra-domain FK allowed (questions->posts, answers->questions, post_tags->posts/tags).
-- vector extension created in V202606181006 (IF NOT EXISTS is idempotent-safe).
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE community_posts (
  id              BIGSERIAL PRIMARY KEY,
  author_id       BIGINT NOT NULL,
  board_type      VARCHAR(16) NOT NULL,
  title           VARCHAR(120) NOT NULL,
  body_md         TEXT NOT NULL,
  body_html       TEXT,
  status          VARCHAR(16) NOT NULL DEFAULT 'PUBLISHED',
  view_count      INT NOT NULL DEFAULT 0,
  upvote_count    INT NOT NULL DEFAULT 0,
  downvote_count  INT NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_community_posts_board CHECK (board_type IN ('QNA','FREE','PROJECT','STUDY','ALUMNI')),
  CONSTRAINT chk_community_posts_status CHECK (status IN ('DRAFT','PUBLISHED','HIDDEN','DELETED'))
);
CREATE INDEX idx_community_posts_board_status_created ON community_posts(board_type, status, created_at DESC);
CREATE INDEX idx_community_posts_author_created ON community_posts(author_id, created_at DESC);
CREATE TRIGGER community_posts_set_updated_at BEFORE UPDATE ON community_posts
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE community_questions (
  post_id            BIGINT PRIMARY KEY REFERENCES community_posts(id) ON DELETE CASCADE,
  is_solved          BOOLEAN NOT NULL DEFAULT FALSE,
  accepted_answer_id BIGINT,
  question_embedding VECTOR(768),
  learning_context   JSONB NOT NULL DEFAULT '{}'
);
CREATE INDEX idx_community_questions_solved ON community_questions(is_solved, post_id DESC);

CREATE TABLE community_answers (
  id              BIGSERIAL PRIMARY KEY,
  question_id     BIGINT NOT NULL REFERENCES community_questions(post_id) ON DELETE CASCADE,
  author_id       BIGINT,
  body_md         TEXT NOT NULL,
  body_html       TEXT,
  is_ai_generated BOOLEAN NOT NULL DEFAULT FALSE,
  is_accepted     BOOLEAN NOT NULL DEFAULT FALSE,
  upvote_count    INT NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_community_answers_question ON community_answers(question_id);
CREATE TRIGGER community_answers_set_updated_at BEFORE UPDATE ON community_answers
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- accepted_answer_id FK는 community_answers 생성 후 추가(순환 정의 회피).
ALTER TABLE community_questions
  ADD CONSTRAINT fk_cq_accepted_answer FOREIGN KEY (accepted_answer_id)
  REFERENCES community_answers(id) ON DELETE SET NULL;

CREATE TABLE community_votes (
  id          BIGSERIAL PRIMARY KEY,
  user_id     BIGINT NOT NULL,
  target_type VARCHAR(8) NOT NULL,
  target_id   BIGINT NOT NULL,
  value       SMALLINT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_community_votes_target CHECK (target_type IN ('POST','ANSWER')),
  CONSTRAINT chk_community_votes_value CHECK (value IN (-1, 1)),
  CONSTRAINT uq_community_votes UNIQUE (user_id, target_type, target_id)
);
CREATE INDEX idx_community_votes_target ON community_votes(target_type, target_id);

CREATE TABLE community_tags (
  id         BIGSERIAL PRIMARY KEY,
  name       VARCHAR(50) NOT NULL UNIQUE,
  post_count INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_community_tags_name_prefix ON community_tags(name text_pattern_ops);

CREATE TABLE community_post_tags (
  post_id BIGINT NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  tag_id  BIGINT NOT NULL REFERENCES community_tags(id) ON DELETE CASCADE,
  PRIMARY KEY (post_id, tag_id)
);
CREATE INDEX idx_community_post_tags_tag ON community_post_tags(tag_id);

CREATE TABLE community_ai_answers (
  question_id     BIGINT PRIMARY KEY REFERENCES community_questions(post_id) ON DELETE CASCADE,
  answer_id       BIGINT REFERENCES community_answers(id) ON DELETE SET NULL,
  model_used      VARCHAR(64),
  prompt_version  VARCHAR(32),
  content         TEXT,
  reference_links JSONB NOT NULL DEFAULT '[]',
  status          VARCHAR(16) NOT NULL,
  error_code      VARCHAR(32),
  generated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_community_ai_answers_status CHECK (status IN ('DONE','FAILED'))
);

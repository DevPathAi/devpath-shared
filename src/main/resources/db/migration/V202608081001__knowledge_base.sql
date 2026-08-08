-- 학습 문서 지식베이스(멘토 RAG 근거). contents/content_embeddings와 분리한다.
-- 분리 이유: contents는 학습 경로 엔진이 소비하고 학습자 화면에 노출된다.
CREATE TABLE knowledge_documents (
  id            BIGSERIAL PRIMARY KEY,
  doc_key       VARCHAR(500) NOT NULL UNIQUE,
  title         VARCHAR(500) NOT NULL,
  category      VARCHAR(100) NOT NULL,
  source_repo   VARCHAR(200) NOT NULL,
  source_commit VARCHAR(40),
  doc_hash      VARCHAR(64)  NOT NULL,
  status        VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE',
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
  CONSTRAINT chk_kd_status CHECK (status IN ('ACTIVE','INACTIVE'))
);

CREATE INDEX idx_knowledge_documents_category ON knowledge_documents(category, status);

CREATE TRIGGER knowledge_documents_set_updated_at BEFORE UPDATE ON knowledge_documents
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE knowledge_embeddings (
  id          BIGSERIAL PRIMARY KEY,
  document_id BIGINT NOT NULL REFERENCES knowledge_documents(id) ON DELETE CASCADE,
  chunk_index INT NOT NULL,
  chunk_text  TEXT NOT NULL,
  embedding   VECTOR(768) NOT NULL,
  chunk_hash  VARCHAR(64),
  status      VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  CONSTRAINT chk_ke_status CHECK (status IN ('ACTIVE','INACTIVE')),
  CONSTRAINT uq_ke_doc_chunk UNIQUE (document_id, chunk_index)
);

CREATE INDEX idx_knowledge_embeddings_hnsw ON knowledge_embeddings
  USING hnsw (embedding vector_cosine_ops) WHERE status = 'ACTIVE';

-- 커뮤니티 FREE/FEEDBACK 보드 + 댓글. board_type에 FEEDBACK 추가, 일반 게시글 댓글 테이블.
ALTER TABLE community_posts DROP CONSTRAINT chk_community_posts_board;
ALTER TABLE community_posts ADD CONSTRAINT chk_community_posts_board
  CHECK (board_type IN ('QNA','FREE','PROJECT','STUDY','ALUMNI','FEEDBACK'));

CREATE TABLE community_comments (
  id           BIGSERIAL PRIMARY KEY,
  post_id      BIGINT NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  author_id    BIGINT NOT NULL,
  body_md      TEXT NOT NULL,
  body_html    TEXT,
  upvote_count INT NOT NULL DEFAULT 0,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_community_comments_post ON community_comments(post_id, created_at);
CREATE TRIGGER community_comments_set_updated_at BEFORE UPDATE ON community_comments
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Deliberately non-transactional: response-loss replay identity must become
-- unique without holding a table-wide writer lock while the index is built.
-- PostgreSQL UNIQUE indexes permit multiple NULLs, preserving old Community rows.
-- Flyway's built-in defaultSchema placeholder binds the table exactly; do not
-- replace this with an unqualified name that can fall through the search_path.
CREATE UNIQUE INDEX CONCURRENTLY uq_lcs_source_draft_id
  ON "${flyway:defaultSchema}".learning_context_snapshots (source_draft_id);

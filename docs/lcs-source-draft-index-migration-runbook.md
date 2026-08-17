# LCS source draft unique index migration runbook

This runbook applies to the unpublished ET9 migration `V202608161010`. The migration is a
nontransactional Flyway Java migration packaged in the migration image. It creates
`uq_lcs_source_draft_id` with `CREATE UNIQUE INDEX CONCURRENTLY` and therefore does not take the
table-wide writer lock used by a regular index build.

## Preconditions

Deploy the new migration image before the LCS consumer. The image must contain a runner JAR in
`/flyway/drivers` and Flyway locations must include both `filesystem:/flyway/sql` and
`classpath:db/migration`.

Check for duplicates before migration:

```sql
SELECT source_draft_id, count(*)
FROM learning_context_snapshots
WHERE source_draft_id IS NOT NULL
GROUP BY source_draft_id
HAVING count(*) > 1;
```

The expected result is zero rows. If the LCS table is absent in a service-specific partial schema,
V1009–V1011 are intentional no-ops and must not create LCS objects there.

## Low-lock sequence

1. V1009 adds a nullable column and `NOT VALID` constraints, so existing rows are not rewritten or
   scanned while writers are blocked.
2. V1010 runs outside a Flyway transaction and builds the unique index concurrently.
3. V1011 validates the constraints after the catalog changes and index build are complete.

Before proceeding, inspect the exact index state:

```sql
SELECT i.indisvalid, i.indisready, i.indisunique, pg_get_indexdef(i.indexrelid)
FROM pg_index i
JOIN pg_class c ON c.oid = i.indexrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = current_schema()
  AND c.relname = 'uq_lcs_source_draft_id';
```

A successful result is valid, ready, unique, and a single-column btree on `source_draft_id`.

## Failed concurrent build recovery

PostgreSQL can leave an invalid index when a concurrent unique build encounters duplicates or is
interrupted. Do not mark that index healthy and do not manually create a second differently named
index.

1. Confirm Flyway reports failed version `202608161010` and inspect `indisvalid`/`indisready`.
2. Run the duplicate query above. Reconcile duplicate rows using the approved data-owner procedure;
   do not delete snapshots solely by timestamp or guess which row is authoritative.
3. After the data issue is resolved, run `flyway repair` with the same URL, user, schema, locations,
   and migration image. This removes the failed nontransactional history entry; it does not repair
   the database object itself.
4. Run `flyway migrate`. The Java migration detects the invalid/not-ready/mismatched index, issues
   top-level `DROP INDEX CONCURRENTLY`, and retries `CREATE UNIQUE INDEX CONCURRENTLY`.
5. Run the index-state query and `flyway validate`. Both `indisvalid` and `indisready` must be true.

If the index is already exact, valid, and ready but only the Flyway history write was lost, the
replayed migration is a no-op and preserves the existing index OID.

Do not deploy the LCS consumer until the final validation succeeds. Sandbox metadata producer is
deployed first, then the shared migration, then LCS, and finally AI consumers.

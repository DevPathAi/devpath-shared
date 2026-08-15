package db.migration;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Optional;
import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

/**
 * Retry-safe, low-lock source draft uniqueness for Mentor snapshots.
 *
 * <p>Concurrent index DDL must be a top-level statement, so this migration deliberately runs
 * outside a Flyway transaction. It is also responsible for cleaning up PostgreSQL's invalid
 * index artifact after a failed concurrent build.
 */
public final class V202608161010__lcs_source_draft_unique_index
    extends BaseJavaMigration {

  private static final String TABLE = "learning_context_snapshots";
  private static final String COLUMN = "source_draft_id";
  private static final String INDEX = "uq_lcs_source_draft_id";

  @Override
  public boolean canExecuteInTransaction() {
    return false;
  }

  @Override
  public void migrate(Context context) throws Exception {
    Connection connection = context.getConnection();
    String schema = configuredSchema(context, connection);
    if (!tableExists(connection, schema)) {
      return;
    }

    Optional<IndexState> existing = indexState(connection, schema);
    if (existing.filter(state -> state.isExactReadyUniqueIndex(schema)).isPresent()) {
      return;
    }

    String quotedSchema = quoteIdentifier(connection, schema);
    String quotedIndex = quoteIdentifier(connection, INDEX);
    String qualifiedIndex = quotedSchema + "." + quotedIndex;
    String qualifiedTable = quotedSchema + "." + quoteIdentifier(connection, TABLE);
    String quotedColumn = quoteIdentifier(connection, COLUMN);
    try (Statement statement = connection.createStatement()) {
      if (existing.isPresent()) {
        statement.execute("DROP INDEX CONCURRENTLY " + qualifiedIndex);
      }
      statement.execute("CREATE UNIQUE INDEX CONCURRENTLY " + quotedIndex
          + " ON " + qualifiedTable + " (" + quotedColumn + ")");
    }
  }

  private static String configuredSchema(Context context, Connection connection)
      throws SQLException {
    String schema = context.getConfiguration().getDefaultSchema();
    if (schema == null || schema.isBlank()) {
      schema = connection.getSchema();
    }
    if (schema == null || schema.isBlank() || schema.indexOf('\0') >= 0) {
      throw new SQLException("Flyway default schema is required for the LCS index migration");
    }
    return schema;
  }

  private static boolean tableExists(Connection connection, String schema) throws SQLException {
    try (PreparedStatement statement = connection.prepareStatement("""
        SELECT 1
        FROM pg_class table_class
        JOIN pg_namespace table_schema ON table_schema.oid=table_class.relnamespace
        WHERE table_schema.nspname=? AND table_class.relname=?
          AND table_class.relkind IN ('r','p')
        """)) {
      statement.setString(1, schema);
      statement.setString(2, TABLE);
      try (ResultSet result = statement.executeQuery()) {
        return result.next();
      }
    }
  }

  private static Optional<IndexState> indexState(Connection connection, String schema)
      throws SQLException {
    try (PreparedStatement statement = connection.prepareStatement("""
        SELECT index_state.indisvalid,
               index_state.indisready,
               index_state.indisunique,
               access_method.amname,
               index_state.indnkeyatts,
               index_state.indnatts,
               pg_get_expr(index_state.indpred,index_state.indrelid),
               pg_get_expr(index_state.indexprs,index_state.indrelid),
               indexed_attribute.attname,
               index_state.indoption[0],
               operator_class.opcdefault,
               index_state.indcollation[0]=indexed_attribute.attcollation,
               NOT index_state.indnullsnotdistinct,
               index_class.reloptions IS NULL,
               index_class.reltablespace=0,
               table_schema.nspname,
               table_class.relname
        FROM pg_class index_class
        JOIN pg_namespace index_schema ON index_schema.oid=index_class.relnamespace
        JOIN pg_index index_state ON index_state.indexrelid=index_class.oid
        JOIN pg_class table_class ON table_class.oid=index_state.indrelid
        JOIN pg_namespace table_schema ON table_schema.oid=table_class.relnamespace
        JOIN pg_am access_method ON access_method.oid=index_class.relam
        LEFT JOIN pg_attribute indexed_attribute
          ON indexed_attribute.attrelid=table_class.oid
         AND indexed_attribute.attnum=index_state.indkey[0]
        LEFT JOIN pg_opclass operator_class ON operator_class.oid=index_state.indclass[0]
        WHERE index_schema.nspname=? AND index_class.relname=?
        """)) {
      statement.setString(1, schema);
      statement.setString(2, INDEX);
      try (ResultSet result = statement.executeQuery()) {
        if (!result.next()) {
          return Optional.empty();
        }
        IndexState state = new IndexState(
            result.getBoolean(1),
            result.getBoolean(2),
            result.getBoolean(3),
            result.getString(4),
            result.getInt(5),
            result.getInt(6),
            result.getString(7),
            result.getString(8),
            result.getString(9),
            result.getInt(10),
            result.getBoolean(11),
            result.getBoolean(12),
            result.getBoolean(13),
            result.getBoolean(14),
            result.getBoolean(15),
            result.getString(16),
            result.getString(17));
        if (result.next()) {
          throw new SQLException("multiple LCS source draft indexes resolved in one schema");
        }
        return Optional.of(state);
      }
    }
  }

  private static String quoteIdentifier(Connection connection, String identifier)
      throws SQLException {
    String quote = connection.getMetaData().getIdentifierQuoteString();
    if (quote == null || quote.isBlank()) {
      throw new SQLException("database does not expose identifier quoting");
    }
    return quote + identifier.replace(quote, quote + quote) + quote;
  }

  private record IndexState(
      boolean valid,
      boolean ready,
      boolean unique,
      String accessMethod,
      int keyAttributes,
      int totalAttributes,
      String predicate,
      String expressions,
      String attribute,
      int options,
      boolean defaultOperatorClass,
      boolean columnCollation,
      boolean defaultNullsDistinct,
      boolean defaultStorageOptions,
      boolean defaultTablespace,
      String tableSchema,
      String tableName) {

    boolean isExactReadyUniqueIndex(String expectedSchema) {
      return valid
          && ready
          && unique
          && "btree".equals(accessMethod)
          && keyAttributes == 1
          && totalAttributes == 1
          && predicate == null
          && expressions == null
          && COLUMN.equals(attribute)
          && options == 0
          && defaultOperatorClass
          && columnCollation
          && defaultNullsDistinct
          && defaultStorageOptions
          && defaultTablespace
          && expectedSchema.equals(tableSchema)
          && TABLE.equals(tableName);
    }
  }
}

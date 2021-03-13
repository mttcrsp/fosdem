import GRDB
import Schedule

struct CreateEventsSearchTable: PersistenceServiceMigration {
  let identifier = "create events search table"

  func perform(in database: GRDB.Database) throws {
    try database.create(virtualTable: Event.searchDatabaseTableName, using: FTS5()) { table in
      table.synchronize(withTable: Event.databaseTableName)
      table.tokenizer = .porter(wrapping: .ascii())

      for column in Event.Columns.searchable {
        table.column(column.rawValue)
      }
    }
  }
}

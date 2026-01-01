import GRDB

struct AddURLColumnToEventsTable: PersistenceServiceMigration {
  let identifier = "add url column to events table"

  func perform(in database: GRDB.Database) throws {
    try database.alter(table: Event.databaseTableName) { table in
      table.add(column: Event.Columns.url.rawValue)
    }
  }
}

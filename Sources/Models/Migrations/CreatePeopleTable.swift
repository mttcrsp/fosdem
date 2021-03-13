import GRDB
import Schedule

struct CreatePeopleTable: PersistenceServiceMigration {
  let identifier = "create people table"

  func perform(in database: Database) throws {
    try database.create(table: Person.databaseTableName) { table in
      table.column(Person.Columns.id.rawValue).primaryKey(onConflict: .replace)
      table.column(Person.Columns.name.rawValue).notNull().indexed()
    }
  }
}

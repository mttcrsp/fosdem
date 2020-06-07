import GRDB

struct CreateParticipationsTable: PersistenceServiceMigration {
  let identifier = "create participations table"

  func perform(in database: Database) throws {
    try database.create(table: Participation.databaseTableName) { table in
      table.column(Participation.Columns.personID.rawValue).notNull()
      table.column(Participation.Columns.eventID.rawValue).notNull()
      table.primaryKey([
        Participation.Columns.eventID.rawValue,
        Participation.Columns.personID.rawValue,
      ], onConflict: .replace)
    }
  }
}

import GRDB

struct CreateEventsTable: PersistenceServiceMigration {
  let identifier = "create events table"

  func perform(in database: GRDB.Database) throws {
    try database.create(table: Event.databaseTableName) { table in
      table.column(Event.Columns.id.rawValue).primaryKey(onConflict: .replace)
      table.column(Event.Columns.room.rawValue).notNull().indexed()
      table.column(Event.Columns.track.rawValue).notNull().indexed()

      table.column(Event.Columns.title.rawValue).notNull()
      table.column(Event.Columns.summary.rawValue)
      table.column(Event.Columns.subtitle.rawValue)
      table.column(Event.Columns.abstract.rawValue)

      table.column(Event.Columns.date.rawValue, .datetime)
      table.column(Event.Columns.start.rawValue).notNull()
      table.column(Event.Columns.duration.rawValue).notNull()

      table.column(Event.Columns.links.rawValue, .blob).notNull()
      table.column(Event.Columns.people.rawValue, .blob).notNull()
      table.column(Event.Columns.attachments.rawValue, .blob).notNull()
    }
  }
}

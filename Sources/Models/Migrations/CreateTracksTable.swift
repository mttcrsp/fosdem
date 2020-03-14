import GRDB

struct CreateTracksTable: PersistenceServiceMigration {
    let identifier = "create tracks table"

    func perform(in database: Database) throws {
        try database.create(table: Track.databaseTableName) { table in
            table.column(Track.Columns.name.rawValue).primaryKey(onConflict: .replace)
            table.column(Track.Columns.day.rawValue, .integer)
            table.column(Track.Columns.date.rawValue, .date)
        }
    }
}

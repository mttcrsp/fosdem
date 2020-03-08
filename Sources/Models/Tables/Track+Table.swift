import GRDB

extension Track: PersistableRecord, FetchableRecord {
    static var databaseTableName: String {
        "tracks"
    }

    enum Columns: String, ColumnExpression {
        case name, day, date
    }

    init(row: Row) {
        self.init(name: row[Columns.name], day: row[Columns.day], date: row[Columns.date])
    }

    func encode(to container: inout PersistenceContainer) {
        container[Columns.day.rawValue] = day
        container[Columns.name.rawValue] = name
        container[Columns.date.rawValue] = date
    }

    static func createTable(in database: Database) throws {
        try database.create(table: Track.databaseTableName) { table in
            table.column(Track.Columns.name.rawValue).primaryKey(onConflict: .replace)
            table.column(Track.Columns.day.rawValue, .integer)
            table.column(Track.Columns.date.rawValue, .date)
        }
    }
}

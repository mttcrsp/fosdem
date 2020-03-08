import GRDB

extension Participation: PersistableRecord, FetchableRecord {
    static var databaseTableName: String {
        "participations"
    }

    enum Columns: String, ColumnExpression {
        case personID, eventID
    }

    static func createTable(in database: Database) throws {
        try database.create(table: Participation.databaseTableName) { table in
            table.column(Participation.Columns.personID.rawValue).notNull()
            table.column(Participation.Columns.eventID.rawValue).notNull()

            let columns = [
                Participation.Columns.eventID.rawValue,
                Participation.Columns.personID.rawValue,
            ]
            table.primaryKey(columns, onConflict: .replace)
        }
    }
}

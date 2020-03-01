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
}

import GRDB

extension Person: PersistableRecord, FetchableRecord {
    static var databaseTableName: String {
        "people"
    }

    enum Columns: String, ColumnExpression {
        case id, name
    }

    init(row: Row) {
        self.init(id: row[Columns.id], name: row[Columns.name])
    }

    func encode(to container: inout PersistenceContainer) {
        container[Columns.id.rawValue] = id
        container[Columns.name.rawValue] = name
    }

    static func createTable(in database: Database) throws {
        try database.create(table: Person.databaseTableName) { table in
            table.column(Person.Columns.id.rawValue).primaryKey(onConflict: .replace)
            table.column(Person.Columns.name.rawValue).notNull().indexed()
        }
    }
}

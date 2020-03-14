import GRDB

struct CreateEventsSearchTable: PersistenceServiceMigration {
    let identifier = "create events search table"

    func perform(in database: GRDB.Database) throws {
        try database.create(virtualTable: Event.searchDatabaseTableName, using: FTS4()) { table in
            table.synchronize(withTable: Event.databaseTableName)
            table.tokenizer = .unicode61()

            for column in Event.Columns.allCases {
                table.column(column.rawValue)
            }
        }
    }
}

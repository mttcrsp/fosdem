import GRDB

extension Participation: PersistableRecord, FetchableRecord {
    static var databaseTableName: String {
        "participations"
    }

    enum Columns: String, ColumnExpression {
        case personID, eventID
    }
}

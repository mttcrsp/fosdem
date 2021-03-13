import GRDB
import Schedule

extension Participation: PersistableRecord, FetchableRecord {
  public static var databaseTableName: String {
    "participations"
  }

  enum Columns: String, ColumnExpression {
    case personID, eventID
  }
}

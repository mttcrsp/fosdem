import GRDB
import Schedule

extension Track: PersistableRecord, FetchableRecord {
  public static var databaseTableName: String {
    "tracks"
  }

  enum Columns: String, ColumnExpression {
    case name, day, date
  }

  public init(row: Row) {
    self.init(name: row[Columns.name], day: row[Columns.day], date: row[Columns.date])
  }

  public func encode(to container: inout PersistenceContainer) {
    container[Columns.day.rawValue] = day
    container[Columns.name.rawValue] = name
    container[Columns.date.rawValue] = date
  }
}

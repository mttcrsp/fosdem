import GRDB
import Schedule

extension Person: PersistableRecord, FetchableRecord {
  public static var databaseTableName: String {
    "people"
  }

  enum Columns: String, ColumnExpression {
    case id, name
  }

  public init(row: Row) {
    self.init(id: row[Columns.id], name: row[Columns.name])
  }

  public func encode(to container: inout PersistenceContainer) {
    container[Columns.id.rawValue] = id
    container[Columns.name.rawValue] = name
  }
}

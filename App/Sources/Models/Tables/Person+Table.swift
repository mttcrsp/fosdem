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
}

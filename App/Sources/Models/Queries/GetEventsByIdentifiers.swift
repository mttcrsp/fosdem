import GRDB

struct GetEventsByIdentifiers: PersistenceServiceRead, Equatable {
  let identifiers: Set<Int>

  func perform(in database: Database) throws -> [Event] {
    try Event.order([Event.Columns.date])
      .filter(identifiers.contains(Event.Columns.id))
      .fetchAll(database)
  }
}

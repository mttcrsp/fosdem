import GRDB

struct AllTracksOrderedByName: PersistenceServiceRead, Equatable {
  func perform(in database: Database) throws -> [Track] {
    try Track
      .filter(!Track.Columns.name.like("% stand"))
      .order(Track.Columns.name.lowercased)
      .fetchAll(database)
  }
}

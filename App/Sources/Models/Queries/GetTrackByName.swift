import GRDB

struct GetTrackByName: PersistenceServiceRead, Equatable {
  let name: String

  func perform(in database: Database) throws -> Track? {
    try Track
      .filter(key: name)
      .fetchOne(database)
  }
}

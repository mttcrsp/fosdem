import GRDB
import Schedule

struct AllTracksOrderedByName: PersistenceServiceRead {
  func perform(in database: Database) throws -> [Track] {
    try Track.order(Track.Columns.name).fetchAll(database)
  }
}

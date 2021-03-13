import GRDB
import Schedule

struct EventsForTrack: PersistenceServiceRead {
  let track: String

  func perform(in database: Database) throws -> [Event] {
    try Event.fetchAll(database, sql: """
    SELECT *
    FROM events
    WHERE track = ?
    ORDER BY date
    """, arguments: [track])
  }
}

import Foundation
import GRDB

struct GetEventsStartingIn30Minutes: PersistenceServiceRead, Equatable {
  let now: Date

  func perform(in database: Database) throws -> [Event] {
    let calendar = Calendar.gregorian
    let upperbound = calendar.date(byAdding: .minute, value: 30, to: now)
    let lowerbound = now

    return try Event.fetchAll(database, sql: """
    SELECT *
    FROM events
    WHERE events.date > ? AND events.date < ?
    ORDER BY date
    """, arguments: [lowerbound, upperbound])
  }
}

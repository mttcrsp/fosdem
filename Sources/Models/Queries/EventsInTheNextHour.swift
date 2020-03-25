import Foundation
import GRDB

struct EventsInTheNextHour: PersistenceServiceRead {
    let now: Date

    func perform(in database: Database) throws -> [Event] {
        let calendar = Calendar.autoupdatingCurrent
        let upperbound = calendar.date(byAdding: .hour, value: 1, to: now)
        let lowerbound = now

        return try Event.fetchAll(database, sql: """
        SELECT *
        FROM events
        WHERE events.date > ? AND events.date < ?
        """, arguments: [lowerbound, upperbound])
    }
}

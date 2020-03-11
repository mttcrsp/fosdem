import GRDB

struct EventsForTrack: PersistenceServiceRead {
    let track: String

    func perform(in database: Database) throws -> [Event] {
        try Event.fetchAll(database, sql: """
        SELECT *
        FROM events
        WHERE track = ?
        """, arguments: [track])
    }
}
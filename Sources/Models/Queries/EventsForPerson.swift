import GRDB

struct EventsForPerson: PersistenceServiceRead {
    let person: Int

    func perform(in database: Database) throws -> [Event] {
        try Event.fetchAll(database, sql: """
        SELECT *
        FROM events JOIN participations ON participations.eventID = events.id
        WHERE participations.personID = ?
        """, arguments: [person])
    }
}

import GRDB

struct EventsForSearch: PersistenceServiceRead {
    let query: String

    func perform(in database: Database) throws -> [Event] {
        try Event.fetchAll(database, sql: """
        SELECT events.*
        FROM events JOIN events_search ON events.id = events_search.id
        WHERE events_search MATCH ?
        """, arguments: [FTS3Pattern(matchingAllTokensIn: query)])
    }
}

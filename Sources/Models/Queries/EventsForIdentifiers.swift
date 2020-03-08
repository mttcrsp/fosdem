import GRDB

struct EventsForIdentifiers: PersistenceServiceRead {
    let identifiers: Set<Int>

    func perform(in database: Database) throws -> [Event] {
        try Event.filter(identifiers.contains(Event.Columns.id)).fetchAll(database)
    }
}

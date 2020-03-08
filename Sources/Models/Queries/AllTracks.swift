import GRDB

struct AllTracks: PersistenceServiceRead {
    func perform(in database: Database) throws -> [Track] {
        try Track.fetchAll(database)
    }
}

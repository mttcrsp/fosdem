import GRDB

final class PersistenceService {
    private let database: DatabaseQueue

    init(path: String?) throws {
        if let path = path {
            database = try DatabaseQueue(path: path)
        } else {
            database = DatabaseQueue()
        }

        try migrator.migrate(database)
    }

    func `import`(_ schedule: Schedule, completion: @escaping (Error?) -> Void) {
        database.asyncWrite({ database in
            for day in schedule.days {
                for event in day.events {
                    try event.insert(database)

                    let track = Track(name: event.track, day: day.index, date: day.date)
                    try track.insert(database)

                    for person in event.people {
                        try person.insert(database)

                        let participation = Participation(personID: person.id, eventID: event.id)
                        try participation.insert(database)
                    }
                }
            }
        }, completion: { _, result in
            switch result {
            case let .failure(error):
                completion(error)
            case .success:
                completion(nil)
            }
        })
    }

    func tracks(completion: @escaping (Result<[Track], Error>) -> Void) {
        database.asyncRead { result in
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .success(database):
                do {
                    completion(.success(try Track.fetchAll(database)))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }

    func events(forTrackWithIdentifier trackID: String, completion: @escaping (Result<[Event], Error>) -> Void) {
        database.asyncRead { result in
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .success(database):
                do {
                    completion(.success(try Event.fetchAll(database, sql: "SELECT * FROM events WHERE track = ?", arguments: [trackID])))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }

    func people(completion: @escaping (Result<[Person], Error>) -> Void) {
        database.asyncRead { result in
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .success(database):
                do {
                    completion(.success(try Person.fetchAll(database)))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }

    func events(forPersonWithIdentifier personID: Int, completion: @escaping (Result<[Event], Error>) -> Void) {
        database.asyncRead { result in
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .success(database):
                do {
                    let sql = """
                    SELECT *
                    FROM events JOIN participations ON participations.eventID = events.id
                    WHERE participations.personID = ?
                    """
                    completion(.success(try Event.fetchAll(database, sql: sql, arguments: [personID])))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }

    func events(withIdentifiers identifiers: Set<Int>, completion: @escaping (Result<[Event], Error>) -> Void) {
        database.asyncRead { result in
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .success(database):
                do {
                    completion(.success(try Event.filter(identifiers.contains(Event.Columns.id)).fetchAll(database)))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }

    func searchEvents(for query: String, completion: @escaping (Result<[Event], Error>) -> Void) {
        database.asyncRead { result in
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .success(database):
                do {
                    let pattern = FTS3Pattern(matchingAllTokensIn: query)
                    let sql = """
                    SELECT events.*
                    FROM events JOIN events_search ON events.id == events_search.id
                    WHERE events_search MATCH ?
                    """
                    let events = try Event.fetchAll(database, sql: sql, arguments: [pattern])
                    completion(.success(events))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("create events table", migrate: createEventsTable)
        migrator.registerMigration("create people table", migrate: createPeopleTable)
        migrator.registerMigration("create tracks table", migrate: createTracksTable)
        migrator.registerMigration("create participations table", migrate: createParticipationsTable)
        migrator.registerMigration("create events search table", migrate: createEventsSearchTable)
        return migrator
    }

    private func createPeopleTable(in database: GRDB.Database) throws {
        try database.create(table: Person.databaseTableName) { table in
            table.column(Person.Columns.id.rawValue).primaryKey(onConflict: .replace)
            table.column(Person.Columns.name.rawValue).notNull().indexed()
        }
    }

    private func createEventsTable(in database: GRDB.Database) throws {
        try database.create(table: Event.databaseTableName) { table in
            table.column(Event.Columns.id.rawValue).primaryKey(onConflict: .replace)
            table.column(Event.Columns.room.rawValue).notNull().indexed()
            table.column(Event.Columns.track.rawValue).notNull().indexed()

            table.column(Event.Columns.title.rawValue).notNull()
            table.column(Event.Columns.summary.rawValue)
            table.column(Event.Columns.subtitle.rawValue)
            table.column(Event.Columns.abstract.rawValue)

            table.column(Event.Columns.start.rawValue).notNull()
            table.column(Event.Columns.duration.rawValue).notNull()

            table.column(Event.Columns.links.rawValue, .blob).notNull()
            table.column(Event.Columns.people.rawValue, .blob).notNull()
            table.column(Event.Columns.attachments.rawValue, .blob).notNull()
        }
    }

    private func createTracksTable(in database: GRDB.Database) throws {
        try database.create(table: Track.databaseTableName) { table in
            table.column(Track.Columns.name.rawValue).primaryKey(onConflict: .replace)
            table.column(Track.Columns.day.rawValue, .integer)
            table.column(Track.Columns.date.rawValue, .date)
        }
    }

    private func createParticipationsTable(in database: GRDB.Database) throws {
        try database.create(table: Participation.databaseTableName) { table in
            table.column(Participation.Columns.personID.rawValue).notNull()
            table.column(Participation.Columns.eventID.rawValue).notNull()

            let columns = [
                Participation.Columns.eventID.rawValue,
                Participation.Columns.personID.rawValue,
            ]
            table.primaryKey(columns, onConflict: .replace)
        }
    }

    private func createEventsSearchTable(in database: GRDB.Database) throws {
        try database.create(virtualTable: Event.searchDatabaseTableName, using: FTS4()) { table in
            table.synchronize(withTable: Event.databaseTableName)
            table.tokenizer = .unicode61()

            for column in Event.Columns.allCases {
                table.column(column.rawValue)
            }
        }
    }
}

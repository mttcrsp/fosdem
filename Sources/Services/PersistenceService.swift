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

    func tracks(completion: @escaping (Result<[String], Error>) -> Void) {
        database.asyncRead { result in
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .success(database):
                do {
                    completion(.success(try String.fetchAll(database, sql: "SELECT DISTINCT track FROM events")))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }

    func events(for track: Track, completion: @escaping (Result<[Event], Error>) -> Void) {
        database.asyncRead { result in
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .success(database):
                do {
                    completion(.success(try Event.fetchAll(database, sql: "SELECT * FROM events WHERE track = ?", arguments: [track])))
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

    func events(forPersonWithIdentifier personID: String, completion: @escaping (Result<[Event], Error>) -> Void) {
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

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("create events table", migrate: createEventsTable)
        migrator.registerMigration("create people table", migrate: createPeopleTable)
        migrator.registerMigration("create participations table", migrate: createParticipationsTable)
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
}

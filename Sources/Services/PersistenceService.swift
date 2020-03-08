import GRDB

protocol PersistenceServiceWrite {
    func perform(in database: Database) throws
}

protocol PersistenceServiceRead {
    func perform(in database: Database) throws -> Model

    associatedtype Model
}

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

    func performWrite(_ write: PersistenceServiceWrite, completion: @escaping (Error?) -> Void) {
        database.asyncWrite({ database in
            try write.perform(in: database)
        }, completion: { _, result in
            switch result {
            case .success:
                completion(nil)
            case let .failure(error):
                completion(error)
            }
        })
    }

    func performRead<Read: PersistenceServiceRead>(_ read: Read, completion: @escaping (Result<Read.Model, Error>) -> Void) {
        database.asyncRead { result in
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .success(database):
                do {
                    completion(.success(try read.perform(in: database)))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }

    func performWriteSync(_ write: PersistenceServiceWrite) throws {
        try database.write(write.perform)
    }

    func performReadSync<Read: PersistenceServiceRead>(_ read: Read) throws -> Read.Model {
        try database.read(read.perform)
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

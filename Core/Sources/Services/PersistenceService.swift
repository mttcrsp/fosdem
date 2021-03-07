import GRDB

public protocol PersistenceServiceWrite {
  func perform(in database: Database) throws
}

protocol PersistenceServiceRead {
  func perform(in database: Database) throws -> Model
  associatedtype Model
}

protocol PersistenceServiceMigration {
  func perform(in database: Database) throws
  var identifier: String { get }
}

public final class PersistenceService {
  private let database: DatabaseQueue

  public convenience init(path: String?) throws {
    try self.init(path: path, migrations: .allMigrations)
  }

  init(path: String?, migrations: [PersistenceServiceMigration]) throws {
    if let path = path {
      database = try DatabaseQueue(path: path)
    } else {
      database = DatabaseQueue()
    }

    var migrator = DatabaseMigrator()
    for migration in migrations {
      migrator.registerMigration(migration.identifier, migrate: migration.perform)
    }
    try migrator.migrate(database)
  }

  public func performWriteSync(_ write: PersistenceServiceWrite) throws {
    try database.write(write.perform)
  }

  func performReadSync<Read: PersistenceServiceRead>(_ read: Read) throws -> Read.Model {
    try database.read(read.perform)
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
}

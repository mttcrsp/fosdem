import GRDB

protocol PersistenceServiceWrite {
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

final class PersistenceService {
  private var database: DatabaseQueue?

  private let path: String?
  private let migrations: [PersistenceServiceMigration]
  
  init(path: String?, migrations: [PersistenceServiceMigration]) {
    self.path = path
    self.migrations = migrations
  }
  
  private func withDatabase<Output>(_ operation: @escaping (DatabaseQueue) throws -> Output) throws -> Output {
    if let database = database {
      return try operation(database)
    }
    
    let database: DatabaseQueue
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
    
    self.database = database
    
    return try operation(database)
  }

  func performWriteSync(_ write: PersistenceServiceWrite) throws {
    try withDatabase { database in
      try database.write(write.perform)
    }
  }

  func performReadSync<Read: PersistenceServiceRead>(_ read: Read) throws -> Read.Model {
    try withDatabase { database in
      try database.read(read.perform)
    }
  }

  func performWrite(_ write: PersistenceServiceWrite, completion: @escaping (Error?) -> Void) {
    do {
      try withDatabase { database in
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
    } catch {
      completion(error)
    }
  }

  func performRead<Read: PersistenceServiceRead>(_ read: Read, completion: @escaping (Result<Read.Model, Error>) -> Void) {
    do {
      try withDatabase { database in
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
    } catch {
      completion(.failure(error))
    }
  }
}

/// @mockable
protocol PersistenceServiceProtocol {
  func performWrite(_ write: PersistenceServiceWrite, completion: @escaping (Error?) -> Void)
  func performWriteSync(_ write: PersistenceServiceWrite) throws

  func performRead<Read>(_ read: Read, completion: @escaping (Result<Read.Model, Error>) -> Void) where Read: PersistenceServiceRead
  func performReadSync<Read>(_ read: Read) throws -> Read.Model where Read: PersistenceServiceRead
}

extension PersistenceService: PersistenceServiceProtocol {}

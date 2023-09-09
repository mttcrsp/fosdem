#if DEBUG
import Foundation

final class GenerateDatabaseService {
  private let fileManager: FileManager
  private let networkService: NetworkService

  init(networkService: NetworkService = .init(session: URLSession.shared), fileManager: FileManager = .default) {
    self.fileManager = fileManager
    self.networkService = networkService
  }

  func generate(completion: @escaping (Result<URL, Error>) -> Void) {
    let databaseFile = fileManager.temporaryDirectory
      .appendingPathComponent("db")
      .appendingPathExtension("sqlite")

    networkService.perform(ScheduleRequest(year: YearsService.current)) { result in
      switch result {
      case let .failure(error):
        completion(.failure(error))
      case let .success(schedule):
        do {
          let persistenceService = try PersistenceService(path: databaseFile.path, migrations: .allMigrations)
          try persistenceService.performWriteSync(UpsertSchedule(schedule: schedule))
          completion(.success(databaseFile))
        } catch {
          completion(.failure(error))
        }
      }
    }
  }
}
#endif

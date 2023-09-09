#if DEBUG
import Foundation

struct GenerateDatabaseService {
  var generate: (@escaping (Result<URL, Error>) -> Void) -> Void
}

extension GenerateDatabaseService {
  init(networkService: NetworkService = .init(session: URLSession.shared), fileManager: FileManager = .default) {
    generate = { completion in
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
}
#endif

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

      _ = networkService.getSchedule(YearsService.current) { result in
        switch result {
        case let .failure(error):
          completion(.failure(error))
        case let .success(schedule):
          do {
            let persistenceService = PersistenceService()
            try persistenceService.load(databaseFile.path)
            persistenceService.upsertSchedule(schedule) { error in
              if let error {
                completion(.failure(error))
              } else {
                completion(.success(databaseFile))
              }
            }
          } catch {
            completion(.failure(error))
          }
        }
      }
    }
  }
}
#endif

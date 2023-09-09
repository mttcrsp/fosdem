#if DEBUG
import Foundation

struct GenerateDatabaseClient {
  var generate: (@escaping (Result<URL, Error>) -> Void) -> Void
}

extension GenerateDatabaseClient {
  init(networkClient: NetworkClient = .init(session: URLSession.shared), fileManager: FileManager = .default) {
    generate = { completion in
      let databaseFile = fileManager.temporaryDirectory
        .appendingPathComponent("db")
        .appendingPathExtension("sqlite")

      _ = networkClient.getSchedule(YearsClient.current) { result in
        switch result {
        case let .failure(error):
          completion(.failure(error))
        case let .success(schedule):
          do {
            let persistenceClient = PersistenceClient()
            try persistenceClient.load(databaseFile.path)
            persistenceClient.upsertSchedule(schedule) { error in
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

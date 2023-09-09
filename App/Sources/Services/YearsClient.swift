import Foundation

struct YearsClient {
  static let current = 2023
  static let all = 2012 ... 2022
  var isYearDownloaded: (Int) -> Bool
  var downloadYear: (Int, @escaping (Swift.Error?) -> Void) -> NetworkClientTask
  var makePersistenceClient: (Int) throws -> PersistenceClientProtocol
}

extension YearsClient {
  enum Error: CustomNSError {
    case documentDirectoryNotFound
    case yearNotAvailable
  }

  init(networkClient: YearsClientNetwork, persistenceClientBuilder: YearsClientPersistenceBuilder = PersistenceClientBuilder(), fileManager: YearsClientFile = FileManager.default) {
    func yearsDirectory() throws -> URL {
      try documentDirectory().appendingPathComponent("years")
    }

    func path(forYear year: Int) throws -> String {
      try documentDirectory().appendingPathComponent(year.description).appendingPathExtension("sqlite").path
    }

    func documentDirectory() throws -> URL {
      if let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
        return url
      } else {
        throw Error.documentDirectoryNotFound
      }
    }

    func makePersistenceClient(for year: Year) throws -> PersistenceClientProtocol {
      try persistenceClientBuilder.makePersistenceClient(withPath: try path(forYear: year))
    }

    self.makePersistenceClient = makePersistenceClient

    downloadYear = { year, completion in
      networkClient.getSchedule(year) { result in
        switch result {
        case .failure(GetSchedule.Error.notFound):
          completion(Error.yearNotAvailable)
        case let .failure(error):
          completion(error)
        case let .success(schedule):
          do {
            try fileManager.createDirectory(at: try yearsDirectory(), withIntermediateDirectories: true, attributes: nil)
            fileManager.createFile(atPath: try path(forYear: year), contents: nil, attributes: nil)

            let persistenceClient = try makePersistenceClient(for: year)
            persistenceClient.upsertSchedule(schedule, completion)
          } catch {
            completion(error)
          }
        }
      }
    }

    isYearDownloaded = { year in
      if let path = try? path(forYear: year) {
        return fileManager.fileExists(atPath: path)
      } else {
        return false
      }
    }
  }
}

/// @mockable
protocol YearsClientProtocol {
  static var current: Int { get }
  static var all: ClosedRange<Int> { get }
  var isYearDownloaded: (Int) -> Bool { get }
  var downloadYear: (Int, @escaping (Swift.Error?) -> Void) -> NetworkClientTask { get }
  var makePersistenceClient: (Int) throws -> PersistenceClientProtocol { get }
}

extension YearsClient: YearsClientProtocol {}

/// @mockable
protocol YearsClientNetwork {
  var getSchedule: (Year, @escaping (Result<Schedule, Error>) -> Void) -> NetworkClientTask { get }
}

extension NetworkClient: YearsClientNetwork {}

/// @mockable
protocol YearsClientPersistenceBuilder {
  func makePersistenceClient(withPath path: String) throws -> PersistenceClientProtocol
}

private class PersistenceClientBuilder: YearsClientPersistenceBuilder {
  func makePersistenceClient(withPath path: String) throws -> PersistenceClientProtocol {
    let persistenceClient = PersistenceClient()
    try persistenceClient.load(path)
    return persistenceClient
  }
}

/// @mockable
protocol YearsClientFile {
  @discardableResult
  func createFile(atPath path: String, contents data: Data?, attributes attr: [FileAttributeKey: Any]?) -> Bool
  func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey: Any]?) throws
  func urls(for directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL]
  func fileExists(atPath path: String) -> Bool
}

extension FileManager: YearsClientFile {}

import Foundation

struct YearsService {
  static let current = 2023
  static let all = 2012 ... 2022
  var isYearDownloaded: (Int) -> Bool
  var downloadYear: (Int, @escaping (Swift.Error?) -> Void) -> NetworkServiceTask
  var makePersistenceService: (Int) throws -> PersistenceServiceProtocol
}

extension YearsService {
  enum Error: CustomNSError {
    case documentDirectoryNotFound
    case yearNotAvailable
  }

  init(networkService: YearsServiceNetwork, persistenceServiceBuilder: YearsServicePersistenceBuilder = PersistenceServiceBuilder(), fileManager: YearsServiceFile = FileManager.default) {
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

    func makePersistenceService(for year: Year) throws -> PersistenceServiceProtocol {
      try persistenceServiceBuilder.makePersistenceService(withPath: try path(forYear: year))
    }

    self.makePersistenceService = makePersistenceService

    downloadYear = { year, completion in
      let request = ScheduleRequest(year: year)
      return networkService.perform(request) { result in
        switch result {
        case .failure(ScheduleRequest.Error.notFound):
          completion(Error.yearNotAvailable)
        case let .failure(error):
          completion(error)
        case let .success(schedule):
          do {
            try fileManager.createDirectory(at: try yearsDirectory(), withIntermediateDirectories: true, attributes: nil)
            fileManager.createFile(atPath: try path(forYear: year), contents: nil, attributes: nil)

            let operation = UpsertSchedule(schedule: schedule)
            let persistenceService = try makePersistenceService(for: year)
            persistenceService.performWrite(operation, completion: completion)
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
protocol YearsServiceProtocol {
  static var current: Int { get }
  static var all: ClosedRange<Int> { get }
  var isYearDownloaded: (Int) -> Bool { get }
  var downloadYear: (Int, @escaping (Swift.Error?) -> Void) -> NetworkServiceTask { get }
  var makePersistenceService: (Int) throws -> PersistenceServiceProtocol { get }
}

extension YearsService: YearsServiceProtocol {}

/// @mockable
protocol YearsServiceNetwork {
  @discardableResult
  func perform(_ request: ScheduleRequest, completion: @escaping (Result<Schedule, Error>) -> Void) -> NetworkServiceTask
}

extension NetworkService: YearsServiceNetwork {}

/// @mockable
protocol YearsServicePersistenceBuilder {
  func makePersistenceService(withPath path: String) throws -> PersistenceServiceProtocol
}

private class PersistenceServiceBuilder: YearsServicePersistenceBuilder {
  func makePersistenceService(withPath path: String) throws -> PersistenceServiceProtocol {
    try PersistenceService(path: path, migrations: .allMigrations)
  }
}

/// @mockable
protocol YearsServiceFile {
  @discardableResult
  func createFile(atPath path: String, contents data: Data?, attributes attr: [FileAttributeKey: Any]?) -> Bool
  func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey: Any]?) throws
  func urls(for directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL]
  func fileExists(atPath path: String) -> Bool
}

extension FileManager: YearsServiceFile {}

protocol HasYearsService {
  var yearsService: YearsServiceProtocol { get }
}

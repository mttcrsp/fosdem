import Foundation

final class YearsService {
  enum Error: CustomNSError {
    case documentDirectoryNotFound
    case yearNotAvailable
  }

  static let current = 2024
  static let all = 2012 ... current - 1

  private let fileManager: YearsServiceFile
  private let networkService: YearsServiceNetwork
  private let persistenceServiceBuilder: YearsServicePersistenceBuilder

  init(networkService: YearsServiceNetwork, persistenceServiceBuilder: YearsServicePersistenceBuilder = PersistenceServiceBuilder(), fileManager: YearsServiceFile = FileManager.default) {
    self.fileManager = fileManager
    self.networkService = networkService
    self.persistenceServiceBuilder = persistenceServiceBuilder
  }

  func downloadYear(_ year: Int, completion: @escaping (Swift.Error?) -> Void) -> NetworkServiceTask {
    let request = ScheduleRequest(year: year)
    return networkService.perform(request) { [weak self] result in
      guard let self else { return }

      switch result {
      case .failure(ScheduleRequest.Error.notFound):
        completion(Error.yearNotAvailable)
      case let .failure(error):
        completion(error)
      case let .success(schedule):
        do {
          let yearsDirectory = try yearsDirectory()
          try fileManager.createDirectory(at: yearsDirectory, withIntermediateDirectories: true, attributes: nil)

          let yearPath = try path(forYear: year)
          fileManager.createFile(atPath: yearPath, contents: nil, attributes: nil)

          let operation = UpsertSchedule(schedule: schedule)
          let persistenceService = try makePersistenceService(forYear: year)
          persistenceService.performWrite(operation, completion: completion)
        } catch {
          completion(error)
        }
      }
    }
  }

  func isYearDownloaded(_ year: Int) -> Bool {
    if let path = try? path(forYear: year) {
      fileManager.fileExists(atPath: path)
    } else {
      false
    }
  }

  func makePersistenceService(forYear year: Int) throws -> PersistenceServiceProtocol {
    try persistenceServiceBuilder.makePersistenceService(withPath: path(forYear: year))
  }

  private func yearsDirectory() throws -> URL {
    try documentDirectory().appendingPathComponent("years")
  }

  private func path(forYear year: Int) throws -> String {
    try documentDirectory().appendingPathComponent(year.description).appendingPathExtension("sqlite").path
  }

  private func documentDirectory() throws -> URL {
    if let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
      return url
    } else {
      throw Error.documentDirectoryNotFound
    }
  }
}

/// @mockable
protocol YearsServiceProtocol {
  static var current: Int { get }
  static var all: ClosedRange<Int> { get }
  func isYearDownloaded(_ year: Int) -> Bool
  func downloadYear(_ year: Int, completion: @escaping (Error?) -> Void) -> NetworkServiceTask
  func makePersistenceService(forYear year: Int) throws -> PersistenceServiceProtocol
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

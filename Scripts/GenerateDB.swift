import Core
import Foundation

@main
struct GenerateDB {
  static let year = 2021

  static func main() {
    var result: Result<Schedule, Error>!

    let semaphore = DispatchSemaphore(value: 0)
    let networkService = NetworkService(session: URLSession.shared)
    let networkRequest = ScheduleRequest(year: year)
    networkService.perform(networkRequest) { networkResult in
      result = networkResult
      semaphore.signal()
    }
    semaphore.wait()

    let tmpDirectory = FileManager.default.homeDirectoryForCurrentUser
    let tmpFile = tmpDirectory
      .appendingPathComponent("db")
      .appendingPathExtension("sqlite")

    let persistenceService = try! PersistenceService(path: tmpFile.path)
    let persistenceRequest = ImportSchedule(schedule: try! result.get())
    try! persistenceService.performWriteSync(persistenceRequest)

    print(tmpFile.path)
  }
}

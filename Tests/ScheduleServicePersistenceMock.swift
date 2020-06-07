@testable
import Fosdem

final class ScheduleServicePersistenceMock: ScheduleServicePersistence {
  private(set) var write: PersistenceServiceWrite?
  private(set) var completion: ((Error?) -> Void)?

  func performWrite(_ write: PersistenceServiceWrite, completion: @escaping (Error?) -> Void) {
    self.write = write
    self.completion = completion
  }

  func reset() {
    write = nil
    completion = nil
  }
}

final class ScheduleServicePersistenceAutomaticMock: ScheduleServicePersistence {
  private(set) var numberOfInvocations = 0

  func performWrite(_: PersistenceServiceWrite, completion: @escaping (Error?) -> Void) {
    numberOfInvocations += 1
    completion(nil)
  }
}

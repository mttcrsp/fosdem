@testable
import Fosdem
import XCTest

final class ScheduleServiceTests: XCTestCase {
  func testUpdate() {
    let persistenceService = ScheduleServicePersistenceMock()
    let networkService = ScheduleServiceNetworkMock()
    let defaults = makeDefaultsMock()

    var networkCompletion: ((Result<Schedule, Error>) -> Void)?
    var persistenceCompletion: ((Error?) -> Void)?

    networkService.performHandler = { _, completion in
      networkCompletion = completion
      return NetworkServiceTaskMock()
    }

    persistenceService.performWriteHandler = { _, completion in
      persistenceCompletion = completion
    }

    let service = ScheduleService(
      fosdemYear: 2021,
      networkService: networkService,
      persistenceService: persistenceService,
      defaults: defaults,
      timeInterval: 10_000_000
    )

    service.startUpdating()
    XCTAssertNotNil(networkCompletion)
    XCTAssertEqual(networkService.performArgValues.first?.url, URL(string: "https://fosdem.org/2021/schedule/xml"))

    networkCompletion?(.success(makeSchedule()))
    XCTAssertNotNil(persistenceCompletion)
    XCTAssert(persistenceService.performWriteArgValues.first is ImportSchedule)

    persistenceCompletion?(nil)
    XCTAssertGreaterThan(defaults.setCallCount, 0)

    service.stopUpdating()
  }

  func testUpdateRepeats() {
    let persistenceService = ScheduleServicePersistenceMock()
    let networkService = ScheduleServiceNetworkMock()
    let defaults = makeDefaultsMock()

    networkService.performHandler = { _, completion in
      completion(.success(self.makeSchedule()))
      return NetworkServiceTaskMock()
    }

    persistenceService.performWriteHandler = { _, completion in
      completion(nil)
    }

    let service = ScheduleService(
      fosdemYear: 2021,
      networkService: networkService,
      persistenceService: persistenceService,
      defaults: defaults,
      timeInterval: 0.1
    )

    service.startUpdating()

    let predicate = NSPredicate { _, _ in
      networkService.performCallCount == 3 &&
        persistenceService.performWriteCallCount == 3
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    XCTWaiter().wait(for: [expectation], timeout: 2)

    service.stopUpdating()
  }

  func testUpdatePreventsUnnecessary() {
    let persistenceService = ScheduleServicePersistenceMock()
    let networkService = ScheduleServiceNetworkMock()
    let defaults = makeDefaultsMock()

    var networkCompletion: ((Result<Schedule, Error>) -> Void)?
    var persistenceCompletion: ((Error?) -> Void)?

    networkService.performHandler = { _, completion in
      networkCompletion = completion
      return NetworkServiceTaskMock()
    }

    persistenceService.performWriteHandler = { _, completion in
      persistenceCompletion = completion
    }

    let service = ScheduleService(
      fosdemYear: 2021,
      networkService: networkService,
      persistenceService: persistenceService,
      defaults: defaults,
      timeInterval: 1
    )

    service.startUpdating()
    networkCompletion?(.success(makeSchedule()))
    persistenceCompletion?(nil)
    service.stopUpdating()

    service.startUpdating()
    XCTAssertEqual(networkService.performCallCount, 1)
    XCTAssertEqual(persistenceService.performWriteCallCount, 1)
    service.stopUpdating()
  }

  func testPreventsSimultaneous() {
    let persistenceService = ScheduleServicePersistenceMock()
    let networkService = ScheduleServiceNetworkMock()
    let defaults = makeDefaultsMock()

    networkService.performHandler = { _, completion in
      completion(.success(self.makeSchedule()))
      return NetworkServiceTaskMock()
    }

    let service = ScheduleService(
      fosdemYear: 2021,
      networkService: networkService,
      persistenceService: persistenceService,
      defaults: defaults,
      timeInterval: 10_000_000_000
    )

    service.startUpdating()
    service.startUpdating()
    service.startUpdating()

    XCTAssertEqual(networkService.performCallCount, 1)

    service.stopUpdating()
  }

  private func makeDefaultsMock() -> ScheduleServiceDefaultsMock {
    var dictionary: [String: Any] = [:]
    let defaults = ScheduleServiceDefaultsMock()
    defaults.setHandler = { value, key in dictionary[key] = value }
    defaults.valueHandler = { key in dictionary[key] }
    return defaults
  }

  private func makeSchedule() -> Schedule {
    .init(conference: Conference(title: "", subtitle: nil, venue: "", city: "", start: .init(), end: .init()), days: [])
  }
}

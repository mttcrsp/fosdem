@testable
import Fosdem
import XCTest

final class ScheduleServiceTests: XCTestCase {
  func testUpdate() {
    let persistenceService = ScheduleServicePersistenceMock()
    let networkService = ScheduleServiceNetworkMock()
    let defaults = ScheduleServiceDefaultsMock()

    let service = ScheduleService(
      fosdemYear: 2021,
      networkService: networkService,
      persistenceService: persistenceService,
      defaults: defaults,
      timeInterval: 10_000_000
    )

    service.startUpdating()
    XCTAssertNotNil(networkService.completion)
    XCTAssertEqual(networkService.request?.url, URL(string: "https://fosdem.org/2021/schedule/xml"))

    networkService.completion?(.success(makeSchedule()))
    XCTAssertNotNil(persistenceService.completion)
    XCTAssert(persistenceService.write is ImportSchedule)

    persistenceService.completion?(nil)
    XCTAssertFalse(defaults.dictionary.isEmpty)

    service.stopUpdating()
  }

  func testUpdateRepeats() {
    let defaults = ScheduleServiceDefaultsMock()
    let persistenceService = ScheduleServicePersistenceAutomaticMock()
    let networkService = ScheduleServiceNetworkAutomaticMock(schedule: makeSchedule())

    let service = ScheduleService(
      fosdemYear: 2021,
      networkService: networkService,
      persistenceService: persistenceService,
      defaults: defaults,
      timeInterval: 0.1
    )

    service.startUpdating()

    let predicate = NSPredicate { _, _ in
      networkService.numberOfInvocations == 3 &&
        persistenceService.numberOfInvocations == 3
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    XCTWaiter().wait(for: [expectation], timeout: 2)

    service.stopUpdating()
  }

  func testUpdatePreventsUnnecessary() {
    let defaults = ScheduleServiceDefaultsMock()
    let networkService = ScheduleServiceNetworkMock()
    let persistenceService = ScheduleServicePersistenceMock()

    let service = ScheduleService(
      fosdemYear: 2021,
      networkService: networkService,
      persistenceService: persistenceService,
      defaults: defaults,
      timeInterval: 1
    )

    service.startUpdating()
    networkService.completion?(.success(makeSchedule()))
    persistenceService.completion?(nil)
    service.stopUpdating()

    networkService.reset()
    persistenceService.reset()

    service.startUpdating()
    XCTAssertNil(networkService.request)
    XCTAssertNil(networkService.completion)
    XCTAssertNil(persistenceService.write)
    XCTAssertNil(persistenceService.completion)
    service.stopUpdating()
  }

  func testPreventsSimultaneous() {
    let defaults = ScheduleServiceDefaultsMock()
    let persistenceService = ScheduleServicePersistenceMock()
    let networkService = ScheduleServiceNetworkAutomaticMock(schedule: makeSchedule())

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

    XCTAssertEqual(networkService.numberOfInvocations, 1)

    service.stopUpdating()
  }

  private func makeSchedule() -> Schedule {
    .init(conference: Conference(title: "", subtitle: nil, venue: "", city: "", start: .init(), end: .init()), days: [])
  }
}

@testable
import Fosdem
import XCTest

final class TimeServiceTests: XCTestCase {
  func testAddObserver() {
    var block: ((TimeServiceTimer) -> Void)?

    let timer = TimeServiceTimerMock()
    timer.invalidateHandler = {
      block = nil
    }

    let timerProvider = TimeServiceProviderMock()
    timerProvider.scheduledTimerHandler = { _, _, receivedBlock in
      block = receivedBlock
      return timer
    }

    let timeService = TimeService(timerProvider: timerProvider)
    timeService.startMonitoring()

    var invocationsCount = 0
    _ = timeService.addObserver {
      invocationsCount += 1
    }

    block?(timer)
    block?(timer)
    block?(timer)

    XCTAssertEqual(invocationsCount, 3)
  }

  func testMonitoring() {
    var block: ((TimeServiceTimer) -> Void)?

    let timer = TimeServiceTimerMock()
    timer.invalidateHandler = {
      block = nil
    }

    let timerProvider = TimeServiceProviderMock()
    timerProvider.scheduledTimerHandler = { _, _, receivedBlock in
      block = receivedBlock
      return timer
    }

    let timeService = TimeService(timerProvider: timerProvider)

    var invocationsCount = 0
    _ = timeService.addObserver {
      invocationsCount += 1
    }

    timeService.startMonitoring()
    block?(timer)
    XCTAssertEqual(invocationsCount, 1)

    timeService.stopMonitoring()
    block?(timer)
    XCTAssertEqual(invocationsCount, 1)

    timeService.startMonitoring()
    block?(timer)
    XCTAssertEqual(invocationsCount, 2)
  }
}

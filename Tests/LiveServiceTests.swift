@testable
import Fosdem
import XCTest

final class LiveServiceTests: XCTestCase {
  func testAddObserver() {
    let timer = LiveServiceTimerMock()
    let timerProvider = LiveServiceProviderMock(timer: timer)
    let liveService = LiveService(timerProvider: timerProvider)
    liveService.startMonitoring()

    var invocationsCount = 0
    _ = liveService.addObserver {
      invocationsCount += 1
    }

    timerProvider.block?(timer)
    timerProvider.block?(timer)
    timerProvider.block?(timer)

    XCTAssertEqual(invocationsCount, 3)
  }

  func testMonitoring() {
    let timer = LiveServiceTimerMock()
    let timerProvider = LiveServiceProviderMock(timer: timer)
    let liveService = LiveService(timerProvider: timerProvider)

    var invocationsCount = 0
    _ = liveService.addObserver {
      invocationsCount += 1
    }

    liveService.startMonitoring()
    timerProvider.block?(timer)
    XCTAssertEqual(invocationsCount, 1)

    liveService.stopMonitoring()
    timerProvider.block?(timer)
    XCTAssertEqual(invocationsCount, 1)

    liveService.startMonitoring()
    timerProvider.block?(timer)
    XCTAssertEqual(invocationsCount, 2)
  }
}

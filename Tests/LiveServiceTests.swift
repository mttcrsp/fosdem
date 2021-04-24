@testable
import Fosdem
import XCTest

final class LiveServiceTests: XCTestCase {
  func testAddObserver() {
    var block: ((LiveServiceTimer) -> Void)?

    let timer = LiveServiceTimerMock()
    timer.invalidateHandler = {
      block = nil
    }

    let timerProvider = LiveServiceProviderMock()
    timerProvider.scheduledTimerHandler = { _, _, receivedBlock in
      block = receivedBlock
      return timer
    }

    let liveService = LiveService(timerProvider: timerProvider)
    liveService.startMonitoring()

    var invocationsCount = 0
    _ = liveService.addObserver {
      invocationsCount += 1
    }

    block?(timer)
    block?(timer)
    block?(timer)

    XCTAssertEqual(invocationsCount, 3)
  }

  func testMonitoring() {
    var block: ((LiveServiceTimer) -> Void)?

    let timer = LiveServiceTimerMock()
    timer.invalidateHandler = {
      block = nil
    }

    let timerProvider = LiveServiceProviderMock()
    timerProvider.scheduledTimerHandler = { _, _, receivedBlock in
      block = receivedBlock
      return timer
    }

    let liveService = LiveService(timerProvider: timerProvider)

    var invocationsCount = 0
    _ = liveService.addObserver {
      invocationsCount += 1
    }

    liveService.startMonitoring()
    block?(timer)
    XCTAssertEqual(invocationsCount, 1)

    liveService.stopMonitoring()
    block?(timer)
    XCTAssertEqual(invocationsCount, 1)

    liveService.startMonitoring()
    block?(timer)
    XCTAssertEqual(invocationsCount, 2)
  }
}

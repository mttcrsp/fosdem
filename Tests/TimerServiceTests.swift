@testable
import Fosdem
import XCTest

final class TimerServiceTests: XCTestCase {
    func testAddObserver() {
        let timer = Timer()
        let timerProvider = TimerServiceProviderMock(timer: timer)
        let timerService = TimerService(timerProvider: timerProvider)
        timerService.startMonitoring()

        let expectation = self.expectation(description: #function)
        expectation.expectedFulfillmentCount = 3

        _ = timerService.addObserver {
            expectation.fulfill()
        }

        timerProvider.block?(timer)
        timerProvider.block?(timer)
        timerProvider.block?(timer)

        waitForExpectations(timeout: 0.1)
    }

    func testStartMonitoring() {
        let timer = Timer()
        let timerProvider = TimerServiceProviderMock(timer: timer)
        let timerService = TimerService(timerProvider: timerProvider)

        let expectation = self.expectation(description: #function)
        expectation.isInverted = true

        _ = timerService.addObserver {
            expectation.fulfill()
        }

        timerProvider.block?(timer)

        waitForExpectations(timeout: 0.1)
    }
}

@testable
import Fosdem
import XCTest

final class LiveServiceTests: XCTestCase {
    func testAddObserver() {
        let timer = Timer()
        let timerProvider = LiveServiceProviderMock(timer: timer)
        let liveService = LiveService(timerProvider: timerProvider)
        liveService.startMonitoring()

        let expectation = self.expectation(description: #function)
        expectation.expectedFulfillmentCount = 3

        _ = liveService.addObserver {
            expectation.fulfill()
        }

        timerProvider.block?(timer)
        timerProvider.block?(timer)
        timerProvider.block?(timer)

        waitForExpectations(timeout: 0.1)
    }

    func testStartMonitoring() {
        let timer = Timer()
        let timerProvider = LiveServiceProviderMock(timer: timer)
        let liveService = LiveService(timerProvider: timerProvider)

        let expectation = self.expectation(description: #function)
        expectation.isInverted = true

        _ = liveService.addObserver {
            expectation.fulfill()
        }

        timerProvider.block?(timer)

        waitForExpectations(timeout: 0.1)
    }
}

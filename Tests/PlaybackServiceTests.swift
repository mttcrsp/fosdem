@testable
import Fosdem
import XCTest

final class PlaybackServiceTests: XCTestCase {
    func testPosition() {
        let userDefaults = PlaybackServiceDefaultsMock()
        let service = PlaybackService(userDefaults: userDefaults)

        let position1 = service.playbackPosition(forEventWithIdentifier: 1)
        let position2 = PlaybackPosition.beginning
        XCTAssertEqual(position1, position2)
    }

    func testSetPositionAt() {
        let identifier = 1
        let position1 = PlaybackPosition.at(99)

        let userDefaults = PlaybackServiceDefaultsMock()
        let service = PlaybackService(userDefaults: userDefaults)
        service.setPlaybackPosition(position1, forEventWithIdentifier: identifier)

        let position2 = service.playbackPosition(forEventWithIdentifier: identifier)
        XCTAssertEqual(position1, position2)
    }

    func testSetPositionEnd() {
        let identifier = 1
        let position1 = PlaybackPosition.end

        let userDefaults = PlaybackServiceDefaultsMock()
        let service = PlaybackService(userDefaults: userDefaults)
        service.setPlaybackPosition(position1, forEventWithIdentifier: identifier)

        let position2 = service.playbackPosition(forEventWithIdentifier: identifier)
        XCTAssertEqual(position1, position2)
    }

    func testSetPositionMixed() {
        let identifier = 1
        let position1 = PlaybackPosition.at(50)
        let position2 = PlaybackPosition.end
        let position3 = PlaybackPosition.at(99)

        let userDefaults = PlaybackServiceDefaultsMock()
        let service = PlaybackService(userDefaults: userDefaults)
        service.setPlaybackPosition(position1, forEventWithIdentifier: identifier)

        let position4 = service.playbackPosition(forEventWithIdentifier: identifier)
        XCTAssertEqual(position1, position4)

        service.setPlaybackPosition(position2, forEventWithIdentifier: identifier)

        let position5 = service.playbackPosition(forEventWithIdentifier: identifier)
        XCTAssertEqual(position2, position5)

        service.setPlaybackPosition(position3, forEventWithIdentifier: identifier)

        let position6 = service.playbackPosition(forEventWithIdentifier: identifier)
        XCTAssertEqual(position3, position6)
    }
}

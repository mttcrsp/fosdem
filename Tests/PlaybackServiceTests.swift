import AVFoundation
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
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 50, preferredTimescale: timeScale)

        let userDefaults = PlaybackServiceDefaultsMock()
        let service = PlaybackService(userDefaults: userDefaults)
        service.setPlaybackPosition(.at(time), forEventWithIdentifier: identifier)

        let position1 = service.playbackPosition(forEventWithIdentifier: identifier)
        let position2 = PlaybackPosition.at(time)
        XCTAssertEqual(position1, position2)
    }

    func testSetPositionEnd() {
        let identifier = 1
        let userDefaults = PlaybackServiceDefaultsMock()
        let service = PlaybackService(userDefaults: userDefaults)
        service.setPlaybackPosition(.end, forEventWithIdentifier: identifier)

        let position1 = service.playbackPosition(forEventWithIdentifier: identifier)
        let position2 = PlaybackPosition.end
        XCTAssertEqual(position1, position2)
    }

    func testSetPositionMixed() {
        let identifier = 1
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time1 = CMTime(seconds: 50, preferredTimescale: timeScale)
        let time2 = CMTime(seconds: 99, preferredTimescale: timeScale)

        let userDefaults = PlaybackServiceDefaultsMock()
        let service = PlaybackService(userDefaults: userDefaults)
        service.setPlaybackPosition(.at(time1), forEventWithIdentifier: identifier)

        let position1 = service.playbackPosition(forEventWithIdentifier: identifier)
        let position2 = PlaybackPosition.at(time1)
        XCTAssertEqual(position1, position2)

        service.setPlaybackPosition(.end, forEventWithIdentifier: identifier)

        let position3 = service.playbackPosition(forEventWithIdentifier: identifier)
        let position4 = PlaybackPosition.end
        XCTAssertEqual(position3, position4)

        service.setPlaybackPosition(.at(time2), forEventWithIdentifier: identifier)

        let position5 = service.playbackPosition(forEventWithIdentifier: identifier)
        let position6 = PlaybackPosition.at(time2)
        XCTAssertEqual(position5, position6)
    }
}

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
    let position4 = PlaybackPosition.beginning

    let userDefaults = PlaybackServiceDefaultsMock()
    let service = PlaybackService(userDefaults: userDefaults)
    service.setPlaybackPosition(position1, forEventWithIdentifier: identifier)

    let position5 = service.playbackPosition(forEventWithIdentifier: identifier)
    XCTAssertEqual(position1, position5)

    service.setPlaybackPosition(position2, forEventWithIdentifier: identifier)

    let position6 = service.playbackPosition(forEventWithIdentifier: identifier)
    XCTAssertEqual(position2, position6)

    service.setPlaybackPosition(position3, forEventWithIdentifier: identifier)

    let position7 = service.playbackPosition(forEventWithIdentifier: identifier)
    XCTAssertEqual(position3, position7)

    service.setPlaybackPosition(position4, forEventWithIdentifier: identifier)

    let position8 = service.playbackPosition(forEventWithIdentifier: identifier)
    XCTAssertEqual(position4, position8)
  }
}

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
    let position1 = PlaybackPosition.at(99)

    let userDefaults = PlaybackServiceDefaultsMock()
    let service = PlaybackService(userDefaults: userDefaults)
    service.setPlaybackPosition(position1, forEventWithIdentifier: .identifier1)

    let position2 = service.playbackPosition(forEventWithIdentifier: .identifier1)
    XCTAssertEqual(position1, position2)
  }

  func testSetPositionEnd() {
    let position1 = PlaybackPosition.end

    let userDefaults = PlaybackServiceDefaultsMock()
    let service = PlaybackService(userDefaults: userDefaults)
    service.setPlaybackPosition(position1, forEventWithIdentifier: .identifier1)

    let position2 = service.playbackPosition(forEventWithIdentifier: .identifier1)
    XCTAssertEqual(position1, position2)
  }

  func testSetPositionMixed() {
    let position1 = PlaybackPosition.at(50)
    let position2 = PlaybackPosition.end
    let position3 = PlaybackPosition.at(99)
    let position4 = PlaybackPosition.beginning

    let userDefaults = PlaybackServiceDefaultsMock()
    let service = PlaybackService(userDefaults: userDefaults)
    service.setPlaybackPosition(position1, forEventWithIdentifier: .identifier1)

    let position5 = service.playbackPosition(forEventWithIdentifier: .identifier1)
    XCTAssertEqual(position1, position5)

    service.setPlaybackPosition(position2, forEventWithIdentifier: .identifier1)

    let position6 = service.playbackPosition(forEventWithIdentifier: .identifier1)
    XCTAssertEqual(position2, position6)

    service.setPlaybackPosition(position3, forEventWithIdentifier: .identifier1)

    let position7 = service.playbackPosition(forEventWithIdentifier: .identifier1)
    XCTAssertEqual(position3, position7)

    service.setPlaybackPosition(position4, forEventWithIdentifier: .identifier1)

    let position8 = service.playbackPosition(forEventWithIdentifier: .identifier1)
    XCTAssertEqual(position4, position8)
  }

  func testWatching() {
    let userDefaults = PlaybackServiceDefaultsMock()
    let service = PlaybackService(userDefaults: userDefaults)
    service.setPlaybackPosition(.at(50), forEventWithIdentifier: .identifier1)
    XCTAssertEqual(service.watching, [.identifier1])

    service.setPlaybackPosition(.at(99), forEventWithIdentifier: .identifier2)
    XCTAssertEqual(service.watching, [.identifier1, .identifier2])

    service.setPlaybackPosition(.beginning, forEventWithIdentifier: .identifier2)
    XCTAssertEqual(service.watching, [.identifier1])

    service.setPlaybackPosition(.end, forEventWithIdentifier: .identifier1)
    XCTAssertEqual(service.watching, [])
  }

  func testWatched() {
    let userDefaults = PlaybackServiceDefaultsMock()
    let service = PlaybackService(userDefaults: userDefaults)
    service.setPlaybackPosition(.end, forEventWithIdentifier: .identifier1)
    XCTAssertEqual(service.watched, [.identifier1])

    service.setPlaybackPosition(.end, forEventWithIdentifier: .identifier2)
    XCTAssertEqual(service.watched, [.identifier1, .identifier2])

    service.setPlaybackPosition(.beginning, forEventWithIdentifier: .identifier2)
    XCTAssertEqual(service.watched, [.identifier1])

    service.setPlaybackPosition(.at(99), forEventWithIdentifier: .identifier2)
    XCTAssertEqual(service.watched, [.identifier1])

    service.setPlaybackPosition(.beginning, forEventWithIdentifier: .identifier1)
    XCTAssertEqual(service.watched, [])
  }

  func testObservers() {
    let userDefaults = PlaybackServiceDefaultsMock()
    let service = PlaybackService(userDefaults: userDefaults)

    var invocationsCount = 0
    let observer = service.addObserver {
      invocationsCount += 1
    }

    service.setPlaybackPosition(.beginning, forEventWithIdentifier: .identifier1)
    XCTAssertEqual(invocationsCount, 0)

    service.setPlaybackPosition(.beginning, forEventWithIdentifier: .identifier1)
    XCTAssertEqual(invocationsCount, 0)

    service.setPlaybackPosition(.at(50), forEventWithIdentifier: .identifier1)
    XCTAssertEqual(invocationsCount, 1)

    service.setPlaybackPosition(.at(50), forEventWithIdentifier: .identifier1)
    XCTAssertEqual(invocationsCount, 1)

    service.setPlaybackPosition(.at(51), forEventWithIdentifier: .identifier1)
    XCTAssertEqual(invocationsCount, 1)

    service.setPlaybackPosition(.beginning, forEventWithIdentifier: .identifier2)
    XCTAssertEqual(invocationsCount, 1)

    service.setPlaybackPosition(.at(99), forEventWithIdentifier: .identifier2)
    XCTAssertEqual(invocationsCount, 2)

    service.setPlaybackPosition(.end, forEventWithIdentifier: .identifier1)
    XCTAssertEqual(invocationsCount, 3)

    service.setPlaybackPosition(.at(100), forEventWithIdentifier: .identifier2)
    XCTAssertEqual(invocationsCount, 3)

    service.setPlaybackPosition(.end, forEventWithIdentifier: .identifier2)
    XCTAssertEqual(invocationsCount, 4)

    service.removeObserver(observer)
    service.setPlaybackPosition(.at(50), forEventWithIdentifier: .identifier1)
    XCTAssertEqual(invocationsCount, 4)
  }
}

private extension Int {
  static var identifier1: Int { 1 }
  static var identifier2: Int { 2 }
}

@testable
import Core
import XCTest

final class FavoritesServiceTests: XCTestCase {
  func testAddTrack() {
    let service = FavoritesService(userDefaults: FavoritesServiceDefaultsMock())
    service.addTrack(withIdentifier: "1")
    XCTAssertEqual(service.tracksIdentifiers, ["1"])

    service.addTrack(withIdentifier: "1")
    XCTAssertEqual(service.tracksIdentifiers, ["1"])

    service.addTrack(withIdentifier: "2")
    XCTAssertEqual(service.tracksIdentifiers, ["1", "2"])

    service.addTrack(withIdentifier: "3")
    XCTAssertEqual(service.tracksIdentifiers, ["1", "2", "3"])

    service.addTrack(withIdentifier: "3")
    XCTAssertEqual(service.tracksIdentifiers, ["1", "2", "3"])
  }

  func testRemoveTrack() {
    let service = FavoritesService(userDefaults: FavoritesServiceDefaultsMock())
    service.addTrack(withIdentifier: "1")
    service.addTrack(withIdentifier: "2")
    service.addTrack(withIdentifier: "3")

    service.removeTrack(withIdentifier: "4")
    XCTAssertEqual(service.tracksIdentifiers, ["1", "2", "3"])

    service.removeTrack(withIdentifier: "3")
    XCTAssertEqual(service.tracksIdentifiers, ["1", "2"])

    service.removeTrack(withIdentifier: "2")
    XCTAssertEqual(service.tracksIdentifiers, ["1"])

    service.removeTrack(withIdentifier: "2")
    XCTAssertEqual(service.tracksIdentifiers, ["1"])

    service.removeTrack(withIdentifier: "1")
    XCTAssertEqual(service.tracksIdentifiers, [])

    service.removeTrack(withIdentifier: "1")
    XCTAssertEqual(service.tracksIdentifiers, [])
  }

  func testAddEvent() {
    let service = FavoritesService(userDefaults: FavoritesServiceDefaultsMock())
    service.addEvent(withIdentifier: 1)
    XCTAssertEqual(service.eventsIdentifiers, [1])

    service.addEvent(withIdentifier: 1)
    XCTAssertEqual(service.eventsIdentifiers, [1])

    service.addEvent(withIdentifier: 2)
    XCTAssertEqual(service.eventsIdentifiers, [1, 2])

    service.addEvent(withIdentifier: 3)
    XCTAssertEqual(service.eventsIdentifiers, [1, 2, 3])

    service.addEvent(withIdentifier: 3)
    XCTAssertEqual(service.eventsIdentifiers, [1, 2, 3])
  }

  func testRemoveEvent() {
    let service = FavoritesService(userDefaults: FavoritesServiceDefaultsMock())
    service.addEvent(withIdentifier: 1)
    service.addEvent(withIdentifier: 2)
    service.addEvent(withIdentifier: 3)

    service.removeEvent(withIdentifier: 4)
    XCTAssertEqual(service.eventsIdentifiers, [1, 2, 3])

    service.removeEvent(withIdentifier: 3)
    XCTAssertEqual(service.eventsIdentifiers, [1, 2])

    service.removeEvent(withIdentifier: 2)
    XCTAssertEqual(service.eventsIdentifiers, [1])

    service.removeEvent(withIdentifier: 2)
    XCTAssertEqual(service.eventsIdentifiers, [1])

    service.removeEvent(withIdentifier: 1)
    XCTAssertEqual(service.eventsIdentifiers, [])

    service.removeEvent(withIdentifier: 1)
    XCTAssertEqual(service.eventsIdentifiers, [])
  }

  func testNotifiesObservers() {
    let tracksExpectation = expectation(description: "tracks changes are notified")
    let eventsExpectation = expectation(description: "events changes are notified")

    for expectation in [tracksExpectation, eventsExpectation] {
      expectation.expectedFulfillmentCount = 2
    }

    let service = FavoritesService(userDefaults: FavoritesServiceDefaultsMock())
    var tracksObservation: NSObjectProtocol? = service.addObserverForTracks { _ in tracksExpectation.fulfill() }
    var eventsObservation: NSObjectProtocol? = service.addObserverForEvents { _ in eventsExpectation.fulfill() }

    service.addTrack(withIdentifier: "1")
    service.addTrack(withIdentifier: "1")
    service.removeTrack(withIdentifier: "1")
    service.removeTrack(withIdentifier: "1")

    service.addEvent(withIdentifier: 1)
    service.addEvent(withIdentifier: 1)
    service.removeEvent(withIdentifier: 1)
    service.removeEvent(withIdentifier: 1)

    waitForExpectations(timeout: 1)

    _ = tracksObservation
    _ = eventsObservation

    tracksObservation = nil
    eventsObservation = nil
  }
}

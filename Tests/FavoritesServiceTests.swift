@testable
import Fosdem
import XCTest

final class FavoritesServiceTests: XCTestCase {
    func testAddTrack() {
        let service = FavoritesService(userDefaults: UserDefaultsMock())
        service.addTrack("1")
        XCTAssertEqual(service.tracks, ["1"])

        service.addTrack("1")
        XCTAssertEqual(service.tracks, ["1"])

        service.addTrack("2")
        XCTAssertEqual(service.tracks, ["1", "2"])

        service.addTrack("3")
        XCTAssertEqual(service.tracks, ["1", "2", "3"])

        service.addTrack("3")
        XCTAssertEqual(service.tracks, ["1", "2", "3"])
    }

    func testRemoveTrack() {
        let service = FavoritesService(userDefaults: UserDefaultsMock())
        service.addTrack("1")
        service.addTrack("2")
        service.addTrack("3")

        service.removeTrack("4")
        XCTAssertEqual(service.tracks, ["1", "2", "3"])

        service.removeTrack("3")
        XCTAssertEqual(service.tracks, ["1", "2"])

        service.removeTrack("2")
        XCTAssertEqual(service.tracks, ["1"])

        service.removeTrack("2")
        XCTAssertEqual(service.tracks, ["1"])

        service.removeTrack("1")
        XCTAssertEqual(service.tracks, [])

        service.removeTrack("1")
        XCTAssertEqual(service.tracks, [])
    }

    func testAddEvent() {
        let service = FavoritesService(userDefaults: UserDefaultsMock())
        service.addEvent(withIdentifier: "1")
        XCTAssertEqual(service.eventsIdentifiers, ["1"])

        service.addEvent(withIdentifier: "1")
        XCTAssertEqual(service.eventsIdentifiers, ["1"])

        service.addEvent(withIdentifier: "2")
        XCTAssertEqual(service.eventsIdentifiers, ["1", "2"])

        service.addEvent(withIdentifier: "3")
        XCTAssertEqual(service.eventsIdentifiers, ["1", "2", "3"])

        service.addEvent(withIdentifier: "3")
        XCTAssertEqual(service.eventsIdentifiers, ["1", "2", "3"])
    }

    func testRemoveEvent() {
        let service = FavoritesService(userDefaults: UserDefaultsMock())
        service.addEvent(withIdentifier: "1")
        service.addEvent(withIdentifier: "2")
        service.addEvent(withIdentifier: "3")

        service.removeEvent(withIdentifier: "4")
        XCTAssertEqual(service.eventsIdentifiers, ["1", "2", "3"])

        service.removeEvent(withIdentifier: "3")
        XCTAssertEqual(service.eventsIdentifiers, ["1", "2"])

        service.removeEvent(withIdentifier: "2")
        XCTAssertEqual(service.eventsIdentifiers, ["1"])

        service.removeEvent(withIdentifier: "2")
        XCTAssertEqual(service.eventsIdentifiers, ["1"])

        service.removeEvent(withIdentifier: "1")
        XCTAssertEqual(service.eventsIdentifiers, [])

        service.removeEvent(withIdentifier: "1")
        XCTAssertEqual(service.eventsIdentifiers, [])
    }
}

private final class UserDefaultsMock: FavoritesServiceDefaults {
    private var dictionary: [String: Any] = [:]

    func set(_ value: Any?, forKey defaultName: String) {
        dictionary[defaultName] = value
    }

    func value(forKey key: String) -> Any? {
        dictionary[key]
    }
}

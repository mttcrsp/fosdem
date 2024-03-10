@testable
import Fosdem
import XCTest

final class FavoritesServiceTests: XCTestCase {
  func testAddTrack() {
    let ubiquitousPreferencesService = makeUbiquitousPreferencesService()
    let preferencesService = makePreferencesService()
    let timeService = makeTimeService()
    let service = FavoritesService(fosdemYear: 2023, preferencesService: preferencesService, ubiquitousPreferencesService: ubiquitousPreferencesService, timeService: timeService)
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

  func testRemoveTrack() throws {
    let ubiquitousPreferencesService = UbiquitousPreferencesServiceProtocolMock()
    let preferencesService = makePreferencesService()
    let service = FavoritesService(fosdemYear: 2023, preferencesService: preferencesService, ubiquitousPreferencesService: ubiquitousPreferencesService, timeService: TimeServiceProtocolMock())
    service.addTrack(withIdentifier: "1")
    service.addTrack(withIdentifier: "2")
    service.addTrack(withIdentifier: "3")

    service.removeTrack(withIdentifier: "4")
    XCTAssertEqual(service.tracksIdentifiers, ["1", "2", "3"])

    service.removeTrack(withIdentifier: "3")
    XCTAssertEqual(service.tracksIdentifiers, ["1", "2"])

    let ubiquitousFavoriteTracks = try XCTUnwrap(ubiquitousPreferencesService.setArgValues.map(\.0).last as? [String: Any])
    let ubiquitousFavoriteTracksValue = ubiquitousFavoriteTracks["value"] as? [String: Any]
    let ubiquitousFavoriteTracksIdentifiers = try XCTUnwrap(ubiquitousFavoriteTracksValue?["identifiers"] as? [String])
    XCTAssertEqual(Set(ubiquitousFavoriteTracksIdentifiers), Set(["1", "2"]))
    XCTAssertEqual(ubiquitousPreferencesService.setArgValues.map(\.1).last, "com.mttcrsp.ansia.FavoritesService.favoriteTracks")

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
    let ubiquitousPreferencesService = UbiquitousPreferencesServiceProtocolMock()
    let preferencesService = makePreferencesService()
    let service = FavoritesService(fosdemYear: 2023, preferencesService: preferencesService, ubiquitousPreferencesService: ubiquitousPreferencesService, timeService: TimeServiceProtocolMock())
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

  func testRemoveEvent() throws {
    let ubiquitousPreferencesService = UbiquitousPreferencesServiceProtocolMock()
    let preferencesService = makePreferencesService()
    let service = FavoritesService(fosdemYear: 2023, preferencesService: preferencesService, ubiquitousPreferencesService: ubiquitousPreferencesService, timeService: TimeServiceProtocolMock())
    service.addEvent(withIdentifier: 1)
    service.addEvent(withIdentifier: 2)
    service.addEvent(withIdentifier: 3)

    service.removeEvent(withIdentifier: 4)
    XCTAssertEqual(service.eventsIdentifiers, [1, 2, 3])

    service.removeEvent(withIdentifier: 3)
    XCTAssertEqual(service.eventsIdentifiers, [1, 2])

    let ubiquitousFavoriteTracks = try XCTUnwrap(ubiquitousPreferencesService.setArgValues.map(\.0).last as? [String: Any])
    let ubiquitousFavoriteTracksValue = ubiquitousFavoriteTracks["value"] as? [String: Any]
    let ubiquitousFavoriteTracksIdentifiers = try XCTUnwrap(ubiquitousFavoriteTracksValue?["identifiers"] as? [Int])
    XCTAssertEqual(Set(ubiquitousFavoriteTracksIdentifiers), Set([1, 2]))
    XCTAssertEqual(ubiquitousPreferencesService.setArgValues.map(\.1).last, "com.mttcrsp.ansia.FavoritesService.favoriteEvents")

    service.removeEvent(withIdentifier: 2)
    XCTAssertEqual(service.eventsIdentifiers, [1])

    service.removeEvent(withIdentifier: 2)
    XCTAssertEqual(service.eventsIdentifiers, [1])

    service.removeEvent(withIdentifier: 1)
    XCTAssertEqual(service.eventsIdentifiers, [])

    service.removeEvent(withIdentifier: 1)
    XCTAssertEqual(service.eventsIdentifiers, [])
  }

  func testNotifiesObservers() throws {
    let tracksExpectation = expectation(description: "tracks changes are notified")
    let eventsExpectation = expectation(description: "events changes are notified")

    for expectation in [tracksExpectation, eventsExpectation] {
      expectation.expectedFulfillmentCount = 2
    }

    let userDefaultsDomain = "com.mttcrsp.test"
    let userDefaults = try XCTUnwrap(UserDefaults(suiteName: userDefaultsDomain))
    defer { userDefaults.removeSuite(named: userDefaultsDomain) }

    let preferencesService = PreferencesService(userDefaults: userDefaults)
    let ubiquitousPreferencesService = UbiquitousPreferencesServiceProtocolMock()
    let service = FavoritesService(fosdemYear: 2023, preferencesService: preferencesService, ubiquitousPreferencesService: ubiquitousPreferencesService, timeService: TimeServiceProtocolMock())
    let tracksObserver: NSObjectProtocol = service.addObserverForTracks { tracksExpectation.fulfill() }
    let eventsObserver: NSObjectProtocol = service.addObserverForEvents { eventsExpectation.fulfill() }

    service.addTrack(withIdentifier: "1")
    service.addTrack(withIdentifier: "1")
    service.removeTrack(withIdentifier: "1")
    service.removeTrack(withIdentifier: "1")

    service.addEvent(withIdentifier: 1)
    service.addEvent(withIdentifier: 1)
    service.removeEvent(withIdentifier: 1)
    service.removeEvent(withIdentifier: 1)

    for observer in [tracksObserver, eventsObserver] {
      service.removeObserver(observer)
    }

    service.addEvent(withIdentifier: 2)
    service.removeEvent(withIdentifier: 2)
    service.addTrack(withIdentifier: "2")
    service.removeTrack(withIdentifier: "2")

    waitForExpectations(timeout: 1)
  }

  func testRemoveAllTracksAndEvents() {
    let eventsExpectation = expectation(description: "events changes are notified")
    let tracksExpectation = expectation(description: "tracks changes are notified")

    let ubiquitousPreferencesService = UbiquitousPreferencesServiceProtocolMock()
    let preferencesService = makePreferencesService()
    let service = FavoritesService(fosdemYear: 2023, preferencesService: preferencesService, ubiquitousPreferencesService: ubiquitousPreferencesService, timeService: TimeServiceProtocolMock())

    service.addEvent(withIdentifier: 1)
    service.addEvent(withIdentifier: 2)
    service.addTrack(withIdentifier: "1")
    service.addTrack(withIdentifier: "2")
    XCTAssertEqual(service.eventsIdentifiers, [1, 2])
    XCTAssertEqual(service.tracksIdentifiers, ["1", "2"])

    var tracksObservation: NSObjectProtocol? = service.addObserverForEvents { eventsExpectation.fulfill() }
    var eventsObservation: NSObjectProtocol? = service.addObserverForTracks { tracksExpectation.fulfill() }
    service.removeAllTracksAndEvents()
    XCTAssertTrue(service.eventsIdentifiers.isEmpty)
    XCTAssertTrue(service.tracksIdentifiers.isEmpty)
    waitForExpectations(timeout: 1)

    _ = tracksObservation
    _ = eventsObservation

    tracksObservation = nil
    eventsObservation = nil
  }

  func testStartMonitoring() {
    let ubiquitousPreferencesService = UbiquitousPreferencesServiceProtocolMock()
    let preferencesService = makePreferencesService()
    let service = FavoritesService(fosdemYear: 2023, preferencesService: preferencesService, ubiquitousPreferencesService: ubiquitousPreferencesService, timeService: TimeServiceProtocolMock())

    var observer: ((String) -> Void)?
    ubiquitousPreferencesService.addObserverHandler = { value in
      observer = value
      return NSObject()
    }

    let date1 = Date().addingTimeInterval(-600)
    let date2 = Date()

    service.startMonitoring()

    let value1 = FavoritesValue(identifiers: [1], year: 2022, updatedAt: date1)
    let value2 = FavoritesValue(identifiers: [2], year: 2023, updatedAt: date1)
    let value3 = FavoritesValue(identifiers: [3], year: 2023, updatedAt: date2)

    preferencesService.valueHandler = { _ in value1.dictionaryValue }
    ubiquitousPreferencesService.valueHandler = { _ in value2.dictionaryValue }
    observer?("com.mttcrsp.ansia.FavoritesService.favoriteTracks")
    XCTAssertEqual(preferencesService.setArgValues.map(\.0) as? [NSDictionary], [value2.dictionaryValue] as [NSDictionary])
    XCTAssertEqual(preferencesService.setArgValues.map(\.1), ["com.mttcrsp.ansia.FavoritesService.favoriteTracks"])
    XCTAssertEqual(preferencesService.setCallCount, 1)
    XCTAssertEqual(ubiquitousPreferencesService.setCallCount, 0)

    preferencesService.valueHandler = { _ in value2.dictionaryValue }
    ubiquitousPreferencesService.valueHandler = { _ in value1.dictionaryValue }
    observer?("com.mttcrsp.ansia.FavoritesService.favoriteTracks")
    XCTAssertEqual(ubiquitousPreferencesService.setArgValues.map(\.0).last as? NSDictionary, value2.dictionaryValue as NSDictionary)
    XCTAssertEqual(ubiquitousPreferencesService.setArgValues.map(\.1).last, "com.mttcrsp.ansia.FavoritesService.favoriteTracks")
    XCTAssertEqual(ubiquitousPreferencesService.setCallCount, 1)
    XCTAssertEqual(preferencesService.setCallCount, 1)

    preferencesService.valueHandler = { _ in value3.dictionaryValue }
    ubiquitousPreferencesService.valueHandler = { _ in value2.dictionaryValue }
    observer?("com.mttcrsp.ansia.FavoritesService.favoriteTracks")
    XCTAssertEqual(ubiquitousPreferencesService.setArgValues.map(\.0).last as? NSDictionary, value3.dictionaryValue as NSDictionary)
    XCTAssertEqual(ubiquitousPreferencesService.setArgValues.map(\.1).last, "com.mttcrsp.ansia.FavoritesService.favoriteTracks")
    XCTAssertEqual(ubiquitousPreferencesService.setCallCount, 2)
    XCTAssertEqual(preferencesService.setCallCount, 1)

    preferencesService.valueHandler = { _ in value2.dictionaryValue }
    ubiquitousPreferencesService.valueHandler = { _ in value3.dictionaryValue }
    observer?("com.mttcrsp.ansia.FavoritesService.favoriteTracks")
    XCTAssertEqual(preferencesService.setArgValues.map(\.0).last as? NSDictionary, value3.dictionaryValue as NSDictionary)
    XCTAssertEqual(preferencesService.setArgValues.map(\.1).last, "com.mttcrsp.ansia.FavoritesService.favoriteTracks")
    XCTAssertEqual(preferencesService.setCallCount, 2)
    XCTAssertEqual(ubiquitousPreferencesService.setCallCount, 2)

    service.stopMonitoring()
  }

  func testStartMonitoringMissingValues() {
    let events = FavoritesValue(identifiers: [1], year: 2023, updatedAt: .init())
    let tracks = FavoritesValue(identifiers: ["2"], year: 2023, updatedAt: .init())

    let ubiquitousPreferencesService = UbiquitousPreferencesServiceProtocolMock()
    ubiquitousPreferencesService.addObserverHandler = { _ in NSObject() }
    ubiquitousPreferencesService.valueHandler = { key in
      switch key {
      case "com.mttcrsp.ansia.FavoritesService.favoriteEvents":
        events.dictionaryValue
      case "com.mttcrsp.ansia.FavoritesService.favoriteTracks":
        tracks.dictionaryValue
      default:
        nil
      }
    }

    let preferencesService = makePreferencesService()
    let service = FavoritesService(fosdemYear: 2023, preferencesService: preferencesService, ubiquitousPreferencesService: ubiquitousPreferencesService, timeService: TimeServiceProtocolMock())
    service.startMonitoring()
    XCTAssertEqual(service.eventsIdentifiers, Set(events.identifiers))
    XCTAssertEqual(service.tracksIdentifiers, Set(tracks.identifiers))
    XCTAssertTrue(ubiquitousPreferencesService.setArgValues.isEmpty)
  }

  func testStartMonitoringMatchingRemote() {
    let events = FavoritesValue(identifiers: [1], year: 2023, updatedAt: .init())
    let tracks = FavoritesValue(identifiers: ["2"], year: 2023, updatedAt: .init())
    let valueHandler: (String) -> Any? = { key in
      switch key {
      case "com.mttcrsp.ansia.FavoritesService.favoriteEvents":
        events.dictionaryValue
      case "com.mttcrsp.ansia.FavoritesService.favoriteTracks":
        tracks.dictionaryValue
      default:
        nil
      }
    }

    let ubiquitousPreferencesService = UbiquitousPreferencesServiceProtocolMock()
    ubiquitousPreferencesService.addObserverHandler = { _ in NSObject() }
    ubiquitousPreferencesService.valueHandler = valueHandler

    let preferencesService = PreferencesServiceProtocolMock()
    preferencesService.valueHandler = valueHandler

    let service = FavoritesService(fosdemYear: 2023, preferencesService: preferencesService, ubiquitousPreferencesService: ubiquitousPreferencesService, timeService: TimeServiceProtocolMock())
    service.startMonitoring()
    XCTAssertTrue(preferencesService.setArgValues.isEmpty)
    XCTAssertTrue(ubiquitousPreferencesService.setArgValues.isEmpty)
  }

  func testStartMonitoringNewerRemote() {
    let date = Date()
    let newEvents = FavoritesValue(identifiers: [1], year: 2023, updatedAt: date)
    let oldEvents = FavoritesValue(identifiers: [2], year: 2022, updatedAt: date)
    let newTracks = FavoritesValue(identifiers: ["3"], year: 2023, updatedAt: date)
    let oldTracks = FavoritesValue(identifiers: ["4"], year: 2023, updatedAt: date.addingTimeInterval(-60))

    let ubiquitousPreferencesService = UbiquitousPreferencesServiceProtocolMock()
    ubiquitousPreferencesService.addObserverHandler = { _ in NSObject() }
    ubiquitousPreferencesService.valueHandler = { key in
      switch key {
      case "com.mttcrsp.ansia.FavoritesService.favoriteEvents":
        newEvents.dictionaryValue
      case "com.mttcrsp.ansia.FavoritesService.favoriteTracks":
        newTracks.dictionaryValue
      default:
        nil
      }
    }

    let preferencesService = makePreferencesService(withInitialValues: [
      "com.mttcrsp.ansia.FavoritesService.favoriteEvents": oldEvents.dictionaryValue,
      "com.mttcrsp.ansia.FavoritesService.favoriteTracks": oldTracks.dictionaryValue,
    ])

    let service = FavoritesService(fosdemYear: 2023, preferencesService: preferencesService, ubiquitousPreferencesService: ubiquitousPreferencesService, timeService: TimeServiceProtocolMock())
    service.startMonitoring()
    XCTAssertEqual(service.eventsIdentifiers, Set(newEvents.identifiers))
    XCTAssertEqual(service.tracksIdentifiers, Set(newTracks.identifiers))
    XCTAssertTrue(ubiquitousPreferencesService.setArgValues.isEmpty)
  }

  func testStartMonitoringOlderRemote() {
    let date = Date()
    let newEvents = FavoritesValue(identifiers: [1], year: 2023, updatedAt: date)
    let oldEvents = FavoritesValue(identifiers: [2], year: 2022, updatedAt: date)
    let newTracks = FavoritesValue(identifiers: ["3"], year: 2023, updatedAt: date)
    let oldTracks = FavoritesValue(identifiers: ["4"], year: 2023, updatedAt: date.addingTimeInterval(-60))

    let ubiquitousPreferencesService = UbiquitousPreferencesServiceProtocolMock()
    ubiquitousPreferencesService.addObserverHandler = { _ in NSObject() }
    ubiquitousPreferencesService.valueHandler = { key in
      switch key {
      case "com.mttcrsp.ansia.FavoritesService.favoriteEvents":
        oldEvents.dictionaryValue
      case "com.mttcrsp.ansia.FavoritesService.favoriteTracks":
        oldTracks.dictionaryValue
      default:
        nil
      }
    }

    let preferencesService = PreferencesServiceProtocolMock()
    preferencesService.valueHandler = { key in
      switch key {
      case "com.mttcrsp.ansia.FavoritesService.favoriteEvents":
        newEvents.dictionaryValue
      case "com.mttcrsp.ansia.FavoritesService.favoriteTracks":
        newTracks.dictionaryValue
      default:
        nil
      }
    }

    let service = FavoritesService(fosdemYear: 2023, preferencesService: preferencesService, ubiquitousPreferencesService: ubiquitousPreferencesService, timeService: TimeServiceProtocolMock())
    service.startMonitoring()

    XCTAssertTrue(preferencesService.setArgValues.isEmpty)
    XCTAssertEqual(ubiquitousPreferencesService.setArgValues.count, 2)
    XCTAssertTrue(
      ubiquitousPreferencesService.setArgValues.contains { argValues in
        argValues.0 as? NSDictionary == newEvents.dictionaryValue as NSDictionary &&
          argValues.1 == "com.mttcrsp.ansia.FavoritesService.favoriteEvents"
      }
    )
    XCTAssertTrue(
      ubiquitousPreferencesService.setArgValues.contains { argValues in
        argValues.0 as? NSDictionary == newTracks.dictionaryValue as NSDictionary &&
          argValues.1 == "com.mttcrsp.ansia.FavoritesService.favoriteTracks"
      }
    )
  }

  func testMigrate() {
    let userDefaults = FavoritesServiceDefaultsMock()
    userDefaults.valueHandler = { key in
      switch key {
      case "favoriteEventsKey":
        [1, 2, 3]
      case "favoriteTracksKey":
        ["4", "5"]
      default:
        nil
      }
    }

    let service = FavoritesService(fosdemYear: 2023, preferencesService: makePreferencesService(), ubiquitousPreferencesService: makeUbiquitousPreferencesService(), timeService: TimeServiceProtocolMock(), userDefaults: userDefaults)
    service.migrate()
    XCTAssertEqual(service.eventsIdentifiers, [1, 2, 3])
    XCTAssertEqual(service.tracksIdentifiers, ["4", "5"])
    XCTAssertEqual(userDefaults.removeObjectArgValues, ["favoriteEventsKey", "favoriteTracksKey"])
  }
}

private extension FavoritesServiceTests {
  struct FavoritesValue<Identifiers> {
    let identifiers: Identifiers, year: Year, updatedAt: Date
    var dictionaryValue: [String: Any] {
      ["updatedAt": updatedAt, "value": ["year": year, "identifiers": identifiers]]
    }
  }

  func makePreferencesService(withInitialValues values: [String: Any] = [:]) -> PreferencesServiceProtocolMock {
    var storage = values
    let preferencesService = PreferencesServiceProtocolMock()
    preferencesService.setHandler = { value, key in storage[key] = value }
    preferencesService.valueHandler = { key in storage[key] }
    return preferencesService
  }

  func makeUbiquitousPreferencesService() -> UbiquitousPreferencesServiceProtocolMock {
    var storage: [String: Any] = [:]
    let ubiquitousPreferencesService = UbiquitousPreferencesServiceProtocolMock()
    ubiquitousPreferencesService.setHandler = { value, key in storage[key] = value }
    ubiquitousPreferencesService.valueHandler = { key in storage[key] }
    return ubiquitousPreferencesService
  }

  func makeTimeService() -> TimeServiceProtocolMock {
    let timeService = TimeServiceProtocolMock()
    timeService.now = Date()
    return timeService
  }
}

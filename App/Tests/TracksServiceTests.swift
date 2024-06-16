@testable
import Fosdem
import XCTest

final class TracksServiceTests: XCTestCase {
  func testLoadConfiguration() {
    let expectation = expectation(description: #function)

    let favoritesService = FavoritesServiceProtocolMock()
    favoritesService.containsTrackHandler = { track in
      ["2", "3"].contains(track.name)
    }

    let track1 = Track(name: "1", day: 1, date: .init())
    let track2 = Track(name: "2", day: 1, date: .init())
    let track3 = Track(name: "3", day: 2, date: .init())
    let track4 = Track(name: "4", day: 2, date: .init())
    let track5 = Track(name: "41", day: 2, date: .init())
    let tracks = [track1, track2, track3, track4, track5]

    var read: Any?
    let persistenceService = PersistenceServiceProtocolMock()
    persistenceService.performReadHandler = { receivedRead, completion in
      read = receivedRead
      if let completion = completion as? ((Result<[Track], Error>) -> Void) {
        completion(.success(tracks))
      }
    }

    let tracksService = TracksService(favoritesService: favoritesService, persistenceService: persistenceService)

    var configuration: TracksConfiguration?
    tracksService.loadConfiguration { value in
      configuration = value
      expectation.fulfill()
    }

    waitForExpectations(timeout: 1)

    XCTAssertEqual(read as? GetAllTracks, .init())
    XCTAssertEqual(configuration?.filters, [.all, .day(1), .day(2)])

    XCTAssertEqual(configuration?.filteredTracks.count, 3)
    XCTAssertEqual(configuration?.filteredTracks[.all], tracks)
    XCTAssertEqual(configuration?.filteredTracks[.day(1)], [track1, track2])
    XCTAssertEqual(configuration?.filteredTracks[.day(2)], [track3, track4, track5])

    XCTAssertEqual(configuration?.filteredFavoriteTracks.count, 3)
    XCTAssertEqual(configuration?.filteredFavoriteTracks[.all], [track2, track3])
    XCTAssertEqual(configuration?.filteredFavoriteTracks[.day(1)], [track2])
    XCTAssertEqual(configuration?.filteredFavoriteTracks[.day(2)], [track3])
  }
}

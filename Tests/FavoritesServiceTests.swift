@testable
import Fosdem
import XCTest

final class FavoritesServiceTests: XCTestCase {
    func testAddTrack() {
        let service = FavoritesService(defaultsService: DefaultsServiceMock())
        service.addTrack("1")
        service.addTrack("2")
        service.addTrack("3")
        XCTAssertEqual(service.tracks, ["1", "2", "3"])
    }

    func testRemoveTrack() {
        let service = FavoritesService(defaultsService: DefaultsServiceMock())
        service.addTrack("1")
        service.addTrack("2")
        service.addTrack("3")
        service.removeTrack("3")
        XCTAssertEqual(service.tracks, ["1", "2"])
        service.removeTrack("2")
        XCTAssertEqual(service.tracks, ["1"])
        service.removeTrack("1")
        XCTAssertEqual(service.tracks, [])
    }

    func testPreservesTrackSorting() {
        let service = FavoritesService(defaultsService: DefaultsServiceMock())
        service.addTrack("c")
        service.addTrack("a")
        XCTAssertEqual(service.tracks, ["a", "c"])
        service.addTrack("b")
        XCTAssertEqual(service.tracks, ["a", "b", "c"])
        service.removeTrack("a")
        XCTAssertEqual(service.tracks, ["b", "c"])
        service.removeTrack("c")
        XCTAssertEqual(service.tracks, ["b"])
    }
}

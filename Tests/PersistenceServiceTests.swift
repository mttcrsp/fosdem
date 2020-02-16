@testable
import Fosdem
import XCTest
import XMLCoder

final class PersistenceServiceTests: XCTestCase {
    func testImport() {
        guard let service = try? PersistenceService(path: nil) else {
            return XCTFail("Failed to instantiate test persistence service")
        }

        let e = expectation(description: #function)
        service.import(schedule) { error in
            XCTAssertNil(error)
            e.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testTracks() {
        guard let service = try? PersistenceService(path: nil) else {
            return XCTFail("Failed to instantiate test persistence service")
        }

        let e = expectation(description: #function)
        service.import(schedule) { _ in
            service.tracks { result in
                switch result {
                case let .failure(error): XCTFail(error.localizedDescription)
                case let .success(tracks): XCTAssertEqual(tracks, ["1", "2", "3"])
                }

                e.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }

    func testEventsForTrack() {
        guard let service = try? PersistenceService(path: nil) else {
            return XCTFail("Failed to instantiate test persistence service")
        }

        let e = expectation(description: #function)
        service.import(schedule) { _ in
            service.events(for: "2") { result in
                switch result {
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                case let .success(events):
                    XCTAssertEqual(events.count, 1)
                    XCTAssertEqual(events.first?.id, "3")
                }

                e.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }

    private var schedule: Schedule {
        let conference = Conference(title: "", subtitle: "", venue: "", city: "", start: .init(), end: .init())
        let event1 = Event(id: "1", room: "", track: "1", title: "", summary: "", subtitle: "", abstract: "", start: .init(), duration: .init(), links: [], people: [], attachments: [])
        let event2 = Event(id: "2", room: "", track: "1", title: "", summary: "", subtitle: "", abstract: "", start: .init(), duration: .init(), links: [], people: [], attachments: [])
        let event3 = Event(id: "3", room: "", track: "2", title: "", summary: "", subtitle: "", abstract: "", start: .init(), duration: .init(), links: [], people: [], attachments: [])
        let event4 = Event(id: "4", room: "", track: "3", title: "", summary: "", subtitle: "", abstract: "", start: .init(), duration: .init(), links: [], people: [], attachments: [])
        let day1 = Day(index: 1, date: .init(), events: [event1, event2])
        let day2 = Day(index: 2, date: .init(), events: [event3, event4])
        return .init(conference: conference, days: [day1, day2])
    }
}

@testable
import Fosdem
import XCTest

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
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                case let .success(tracks):
                    let names = Set(tracks.map { track in track.name })
                    XCTAssertEqual(names, ["1", "2", "3"])
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
            service.events(forTrackWithIdentifier: "2") { result in
                switch result {
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                case let .success(events):
                    XCTAssertEqual(events.count, 1)
                    XCTAssertEqual(events.first?.id, 3)
                }

                e.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }

    func testPeople() {
        guard let service = try? PersistenceService(path: nil) else {
            return XCTFail("Failed to instantiate test persistence service")
        }

        let e = expectation(description: #function)
        service.import(schedule) { _ in
            service.people { result in
                switch result {
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                case let .success(people):
                    XCTAssertEqual(people.count, 2)
                    XCTAssertEqual(people.first?.id, 1)
                    XCTAssertEqual(people.last?.id, 2)
                }

                e.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }

    func testEventsForPerson() {
        guard let service = try? PersistenceService(path: nil) else {
            return XCTFail("Failed to instantiate test persistence service")
        }

        let e = expectation(description: #function)
        service.import(schedule) { _ in
            service.events(forPersonWithIdentifier: 2) { result in
                switch result {
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                case let .success(events):
                    XCTAssertEqual(events.count, 2)
                    XCTAssertEqual(events.first?.id, 1)
                    XCTAssertEqual(events.last?.id, 3)
                }

                e.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }

    func testEventsWithIdentifiers() {
        guard let service = try? PersistenceService(path: nil) else {
            return XCTFail("Failed to instantiate test persistence service")
        }

        let e = expectation(description: #function)
        service.import(schedule) { _ in
            service.events(withIdentifiers: [1, 4]) { result in
                switch result {
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                case let .success(events):
                    XCTAssertEqual(events.count, 2)
                    XCTAssertEqual(events.first?.id, 1)
                    XCTAssertEqual(events.last?.id, 4)
                }

                e.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }

    private var schedule: Schedule {
        let conference = Conference(title: "", subtitle: "", venue: "", city: "", start: .init(), end: .init())
        let person1 = Person(id: 1, name: "1")
        let person2 = Person(id: 2, name: "2")
        let event1 = Event(id: 1, room: "", track: "1", title: "", summary: "", subtitle: "", abstract: "", start: .init(), duration: .init(), links: [], people: [person1, person2], attachments: [])
        let event2 = Event(id: 2, room: "", track: "1", title: "", summary: "", subtitle: "", abstract: "", start: .init(), duration: .init(), links: [], people: [person1], attachments: [])
        let event3 = Event(id: 3, room: "", track: "2", title: "", summary: "", subtitle: "", abstract: "", start: .init(), duration: .init(), links: [], people: [person2], attachments: [])
        let event4 = Event(id: 4, room: "", track: "3", title: "", summary: "", subtitle: "", abstract: "", start: .init(), duration: .init(), links: [], people: [], attachments: [])
        let day1 = Day(index: 1, date: .init(), events: [event1, event2])
        let day2 = Day(index: 2, date: .init(), events: [event3, event4])
        return .init(conference: conference, days: [day1, day2])
    }
}

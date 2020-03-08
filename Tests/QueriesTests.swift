@testable
import Fosdem
import GRDB
import XCTest

final class QueriesTests: XCTestCase {
    func testImport() {
        XCTAssertNoThrow(({
            let operation = ImportSchedule(schedule: self.makeSchedule())
            let service = try self.makePersistenceService()
            try service.performWriteSync(operation)
        }))
    }

    func testAllTracks() {
        XCTAssertNoThrow(({
            let service = try self.makePersistentServiceWithSchedule()
            let tracks = try service.performReadSync(AllTracks())
            let names = Set(tracks.map { track in track.name })
            XCTAssertEqual(names, ["1", "2", "3"])
        }))
    }

    func testEventsForTrack() {
        XCTAssertNoThrow(({
            let service = try self.makePersistentServiceWithSchedule()
            let events = try service.performReadSync(EventsForTrack(track: "2"))
            XCTAssertEqual(events.count, 1)
            XCTAssertEqual(events.first?.id, 3)
        }))
    }

    func testEventsForPerson() {
        XCTAssertNoThrow(({
            let service = try self.makePersistentServiceWithSchedule()
            let events = try service.performReadSync(EventsForPerson(person: 2))
            XCTAssertEqual(events.count, 2)
            XCTAssertEqual(events.first?.id, 1)
            XCTAssertEqual(events.last?.id, 3)
        }))
    }

    func testEventsForIdentifiers() {
        XCTAssertNoThrow(({
            let service = try self.makePersistentServiceWithSchedule()
            let events = try service.performReadSync(EventsForIdentifiers(identifiers: [1, 4]))
            XCTAssertEqual(events.count, 2)
            XCTAssertEqual(events.first?.id, 1)
            XCTAssertEqual(events.last?.id, 4)
        }))
    }

    func testEventsForSearch() {
        XCTAssertNoThrow(({
            let service = try self.makePersistentServiceWithSchedule()
            let events = try service.performReadSync(EventsForSearch(query: "title 4"))
            XCTAssertEqual(events.count, 1)
        }))
    }

    private func makePersistenceService() throws -> PersistenceService {
        try PersistenceService(path: nil)
    }

    private func makePersistentServiceWithSchedule() throws -> PersistenceService {
        let operation = ImportSchedule(schedule: makeSchedule())
        let service = try makePersistenceService()
        try service.performWriteSync(operation)
        return service
    }

    private func makeSchedule() -> Schedule {
        let person1 = Person(id: 1, name: "1")
        let person2 = Person(id: 2, name: "2")
        let event1 = Event(id: 1, room: "", track: "1", title: "title 1", summary: "", subtitle: "", abstract: "", start: .init(), duration: .init(), links: [], people: [person1, person2], attachments: [])
        let event2 = Event(id: 2, room: "", track: "1", title: "title 2", summary: "", subtitle: "", abstract: "", start: .init(), duration: .init(), links: [], people: [person1], attachments: [])
        let event3 = Event(id: 3, room: "", track: "2", title: "title 3", summary: "", subtitle: "", abstract: "", start: .init(), duration: .init(), links: [], people: [person2], attachments: [])
        let event4 = Event(id: 4, room: "", track: "3", title: "title 4", summary: "", subtitle: "", abstract: "", start: .init(), duration: .init(), links: [], people: [], attachments: [])
        let conference = Conference(title: "", subtitle: "", venue: "", city: "", start: .init(), end: .init())
        let day1 = Day(index: 1, date: .init(), events: [event1, event2])
        let day2 = Day(index: 2, date: .init(), events: [event3, event4])
        return .init(conference: conference, days: [day1, day2])
    }
}

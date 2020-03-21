@testable
import Fosdem
import GRDB
import XCTest

final class QueriesTests: XCTestCase {
    func testImport() {
        XCTAssertNoThrow(try {
            let operation = ImportSchedule(schedule: self.makeSchedule())
            let service = try self.makePersistenceService()
            try service.performWriteSync(operation)
        }())
    }

    func testAllTracks() {
        XCTAssertNoThrow(try {
            let service = try self.makePersistentServiceWithSchedule()
            let tracks = try service.performReadSync(AllTracksOrderedByName())

            let names1 = tracks.map { track in track.name }
            let names2 = ["1", "2", "5"]
            XCTAssertEqual(names1, names2)

            let track = tracks.first
            XCTAssertEqual(track?.day, 1)
            XCTAssertEqual(track?.name, "1")
        }())
    }

    func testEventsForTrack() {
        XCTAssertNoThrow(try {
            let service = try self.makePersistentServiceWithSchedule()
            let events = try service.performReadSync(EventsForTrack(track: "2"))
            XCTAssertEqual(events.count, 2)

            let identifiers = events.map { event in event.id }
            XCTAssertEqual(identifiers, [3, 4])

            let event = events.first
            XCTAssertEqual(event?.id, 3)
            XCTAssertEqual(event?.room, "room")
            XCTAssertEqual(event?.track, "2")
            XCTAssertEqual(event?.title, "title 3")
            XCTAssertEqual(event?.summary, "summary")
            XCTAssertEqual(event?.abstract, "abstract")
            XCTAssertEqual(event?.subtitle, "subtitle")
            XCTAssertEqual(event?.people, [Person(id: 2, name: "2")])
            XCTAssertEqual(event?.start, DateComponents(hour: 9, minute: 30))
            XCTAssertEqual(event?.duration, DateComponents(hour: 10, minute: 45))
            XCTAssertEqual(event?.links, [Link(name: "name", url: URL(string: "https://www.fosdem.org"))])
            XCTAssertEqual(event?.attachments, [Attachment(type: .paper, url: URL(string: "https://www.fosdem.org")!, name: "name")])

            guard let eventDate = event?.date else {
                XCTAssertNotNil(event?.date)
                return
            }

            let calendar = Calendar.autoupdatingCurrent
            let calendarComponents: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]
            let date = Date(timeIntervalSince1970: 30_000_000)
            let dateComponents1 = calendar.dateComponents(calendarComponents, from: date)
            let dateComponents2 = calendar.dateComponents(calendarComponents, from: eventDate)
            XCTAssertEqual(dateComponents1, dateComponents2)
        }())
    }

    func testEventsForPerson() {
        XCTAssertNoThrow(try {
            let service = try self.makePersistentServiceWithSchedule()
            let events = try service.performReadSync(EventsForPerson(person: 2))
            XCTAssertEqual(events.count, 2)
            XCTAssertEqual(events.first?.id, 1)
            XCTAssertEqual(events.first?.id, 1)
        }())
    }

    func testEventsForIdentifiers() {
        XCTAssertNoThrow(try {
            let service = try self.makePersistentServiceWithSchedule()
            let events = try service.performReadSync(EventsForIdentifiers(identifiers: [4, 1, 2]))
            XCTAssertEqual(events.count, 3)

            let identifiers = events.map { event in event.id }
            XCTAssertEqual(identifiers, [1, 2, 4])
        }())
    }

    func testEventsForSearch() {
        XCTAssertNoThrow(try {
            let service = try self.makePersistentServiceWithSchedule()
            let events = try service.performReadSync(EventsForSearch(query: "title 4"))
            XCTAssertEqual(events.count, 1)
        }())
    }

    private func makePersistenceService() throws -> PersistenceService {
        try PersistenceService(path: nil, migrations: .allMigrations)
    }

    private func makePersistentServiceWithSchedule() throws -> PersistenceService {
        let operation = ImportSchedule(schedule: makeSchedule())
        let service = try makePersistenceService()
        try service.performWriteSync(operation)
        return service
    }

    private func makeSchedule() -> Schedule {
        let url = URL(string: "https://www.fosdem.org")!
        let attachment = Attachment(type: .paper, url: url, name: "name")
        let duration = DateComponents(hour: 10, minute: 45)
        let start = DateComponents(hour: 9, minute: 30)
        let link = Link(name: "name", url: url)
        let person1 = Person(id: 1, name: "1")
        let person2 = Person(id: 2, name: "2")
        let date1 = Date(timeIntervalSince1970: 10_000_000)
        let date2 = Date(timeIntervalSince1970: 20_000_000)
        let date3 = Date(timeIntervalSince1970: 30_000_000)
        let date4 = Date(timeIntervalSince1970: 40_000_000)
        let event1 = Event(id: 1, room: "room", track: "5", title: "title 1", summary: "summary", subtitle: "subtitle", abstract: "abstract", date: date1, start: start, duration: duration, links: [link], people: [person1, person2], attachments: [attachment])
        let event2 = Event(id: 2, room: "room", track: "1", title: "title 2", summary: "summary", subtitle: "subtitle", abstract: "abstract", date: date2, start: start, duration: duration, links: [link], people: [person1], attachments: [attachment])
        let event3 = Event(id: 3, room: "room", track: "2", title: "title 3", summary: "summary", subtitle: "subtitle", abstract: "abstract", date: date3, start: start, duration: duration, links: [link], people: [person2], attachments: [attachment])
        let event4 = Event(id: 4, room: "room", track: "2", title: "title 4", summary: "summary", subtitle: "subtitle", abstract: "abstract", date: date4, start: start, duration: duration, links: [link], people: [], attachments: [attachment])
        let conference = Conference(title: "", subtitle: "", venue: "", city: "", start: .init(), end: .init())
        let day1 = Day(index: 1, date: .init(), events: [event2, event1])
        let day2 = Day(index: 2, date: .init(), events: [event4, event3])
        return .init(conference: conference, days: [day1, day2])
    }
}

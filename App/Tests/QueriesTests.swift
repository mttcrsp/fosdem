@testable
import Fosdem
import GRDB
import XCTest

final class QueriesTests: XCTestCase {
  func testImport() throws {
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
    let schedule = Schedule(conference: conference, days: [day1, day2])

    let operation = UpsertSchedule(schedule: schedule)
    let service = try makePersistenceService()
    try service.performWriteSync(operation)
  }

  func testAllTracksOrderedByName() throws {
    let date = Date()
    let event1 = Event.make(id: 1, track: "C")
    let event2 = Event.make(id: 2, track: "C")
    let event3 = Event.make(id: 3, track: "a")
    let event4 = Event.make(id: 4, track: "a")
    let event5 = Event.make(id: 5, track: "B")
    let event6 = Event.make(id: 6, track: "B Stand")
    let day1 = Day.make(index: 1, date: date, events: [event1, event2])
    let day2 = Day.make(index: 2, date: date, events: [event3, event4, event5, event6])
    let schedule = Schedule.make(days: [day1, day2])

    let query = GetAllTracks()
    let service = try makePersistentService(with: schedule)
    let tracks = try service.performReadSync(query)

    XCTAssertEqual(tracks, [
      Track(name: "a", day: 2, date: Date()),
      Track(name: "B", day: 2, date: Date()),
      Track(name: "C", day: 1, date: Date()),
    ])
  }

  func testEventsForTrack() throws {
    let date1 = Date()
    let date2 = Date().addingTimeInterval(1000)
    let event1 = Event.make(id: 1, track: "1")
    let event2 = Event.make(id: 2, track: "2")
    let event3 = Event.make(id: 3, track: "3", date: date2)
    let event4 = Event.make(id: 4, track: "3", date: date1)
    let event5 = Event.make(id: 5, track: "4")
    let schedule = Schedule.make(days: [.make(events: [event1, event2, event3, event4, event5])])

    let query = GetEventsByTrack(track: "3")
    let service = try makePersistentService(with: schedule)
    let events = try service.performReadSync(query)

    XCTAssertEqual(events, [event4, event3])
  }

  func testEventsForIdentifiers() throws {
    let event1 = Event.make(id: 1)
    let event2 = Event.make(id: 2)
    let event3 = Event.make(id: 3)
    let event4 = Event.make(id: 4)
    let schedule = Schedule.make(days: [.make(events: [event1, event2, event3, event4])])

    let query = GetEventsByIdentifiers(identifiers: [2, 3])
    let service = try makePersistentService(with: schedule)
    let events = try service.performReadSync(query)

    XCTAssertEqual(events, [event2, event3])
  }

  func testEventsForSearch() throws {
    let event1 = Event.make(id: 1)
    let event2 = Event.make(id: 2, title: "asdf query adsf")
    let event3 = Event.make(id: 3, track: "asdf query adsf")
    let event4 = Event.make(id: 4, summary: "asdf query adsf")
    let event5 = Event.make(id: 5, abstract: "asdf query adsf")
    let event6 = Event.make(id: 6, subtitle: "asdf query adsf")
    let event7 = Event.make(id: 7, people: [.init(id: 1, name: "asdf query adsf")])
    let allEvents = [event1, event2, event3, event4, event5, event6, event7]
    let schedule = Schedule.make(days: [.make(events: allEvents)])

    let query = GetEventsBySearch(query: "query")
    let service = try makePersistentService(with: schedule)
    let events = try service.performReadSync(query)

    XCTAssertEqual(events, [event2, event6, event3, event7, event4, event5])
  }

  func testEventsStartingIn30Minutes() throws {
    let date1 = Date()
    let date2 = Date().addingTimeInterval(600)
    let date3 = Date().addingTimeInterval(1650)
    let date4 = Date().addingTimeInterval(1801)
    let date5 = Date().addingTimeInterval(1_000_000)

    let event1 = Event.make(id: 1, date: date1)
    let event2 = Event.make(id: 2, date: date3)
    let event3 = Event.make(id: 3, date: date2)
    let event4 = Event.make(id: 4, date: date4)
    let event5 = Event.make(id: 5, date: date5)
    let schedule = Schedule.make(days: [.make(events: [event1, event2, event3, event4, event5])])

    let query = GetEventsStartingIn30Minutes(now: date1)
    let service = try makePersistentService(with: schedule)
    let events = try service.performReadSync(query)

    XCTAssertEqual(events, [event3, event2])
  }

  private func makePersistenceService() throws -> PersistenceService {
    try PersistenceService(path: nil, migrations: .allMigrations)
  }

  private func makePersistentService(with schedule: Schedule) throws -> PersistenceService {
    let operation = UpsertSchedule(schedule: schedule)
    let service = try makePersistenceService()
    try service.performWriteSync(operation)
    return service
  }
}

private extension Event {
  static func make(id: Int, room: String = "room", track: String = "track", title: String = "title", summary: String? = nil, subtitle: String? = nil, abstract: String? = nil, date: Date = .init(), start: DateComponents = .init(), duration: DateComponents = .init(), links: [Link] = [], people: [Person] = [], attachments: [Attachment] = []) -> Event {
    .init(id: id, room: room, track: track, title: title, summary: summary, subtitle: subtitle, abstract: abstract, date: date, start: start, duration: duration, links: links, people: people, attachments: attachments)
  }
}

private extension Conference {
  static func make(title: String = "", subtitle: String? = nil, venue: String = "", city: String = "", start: Date = .init(), end: Date = .init()) -> Conference {
    .init(title: title, subtitle: subtitle, venue: venue, city: city, start: start, end: end)
  }
}

private extension Day {
  static func make(index: Int = .random(in: 1 ... 2), date: Date = .init(), events: [Event] = []) -> Day {
    .init(index: index, date: date, events: events)
  }
}

private extension Schedule {
  static func make(conference: Conference = .make(), days: [Day] = []) -> Schedule {
    .init(conference: conference, days: days)
  }
}

private extension Track {
  static func make(name: String = "name", day: Int = .random(in: 1 ... 2), date: Date = .init()) -> Track {
    .init(name: name, day: day, date: date)
  }
}

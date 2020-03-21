@testable
import Fosdem
import XCTest

final class EventTests: XCTestCase {
    func testSortByStart() {
        let event1 = makeEvent(withIdentifier: 1, start: .init(hour: 11, minute: 40))
        let event2 = makeEvent(withIdentifier: 2, start: .init(hour: 16, minute: 20))
        let sorted = [event2, event1].sortedByStart()
        XCTAssertEqual(sorted, [event1, event2])
    }

    func testSortByStartMinute() {
        let event1 = makeEvent(withIdentifier: 1, start: .init(hour: 10, minute: 20))
        let event2 = makeEvent(withIdentifier: 2, start: .init(hour: 10, minute: 55))
        let sorted = [event2, event1].sortedByStart()
        XCTAssertEqual(sorted, [event1, event2])
    }

    private func makeEvent(withIdentifier id: Int, start: DateComponents) -> Event {
        .init(id: id, room: "", track: "", title: "", summary: "", subtitle: "", abstract: "", date: .init(), start: start, duration: .init(), links: [], people: [], attachments: [])
    }
}

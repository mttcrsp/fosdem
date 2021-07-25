@testable
import Fosdem
import XCTest

final class SoonServiceTests: XCTestCase {
  func testLoadEvents() throws {
    let event = try Event.from(#"{"room":"D.apache.openoffice","people":[{"id":5243,"name":"Peter Kovacs"}],"start":{"minute":30,"hour":10},"id":11717,"track":"Apache OpenOffice","title":"State of Apache OpenOffice","date":634296600,"abstract":"<p>Time to look on the past year, and asses where is the Project.\nThis talk will summerize the 2020 reports, give an overview on Discussions and Activities within the Project.\nIf you want a quick look where the Project is and where we head, then Visit this Talk!</p>","duration":{"minute":45,"hour":0},"links":[{"name":"Video recording (WebM/VP9)","url":"https://video.fosdem.org/2021/D.apache.openoffice/openoffice_state.webm"},{"name":"Video recording (mp4)","url":"https://video.fosdem.org/2021/D.apache.openoffice/openoffice_state.mp4"},{"name":"Submit feedback","url":"https://submission.fosdem.org/feedback/11717.php"}],"attachments":[{"type":"slides","url":"https://fosdem.org/2021/schedule/event/openoffice_state/attachments/slides/4490/export/events/attachments/openoffice_state/slides/4490/Status_AOO_2020.odp"}]}"#)

    let timeService = TimeServiceProtocolMock()
    timeService.now = Date()

    var request: Any?
    let persistenceService = PersistenceServiceProtocolMock()
    persistenceService.performReadHandler = { receivedRequest, completion in
      request = receivedRequest

      if let completion = completion as? ((Result<[Event], Error>) -> Void) {
        completion(.success([event]))
      }
    }

    var result: Result<[Event], Error>?
    let service = SoonService(timeService: timeService, persistenceService: persistenceService)
    service.loadEvents { receivedResult in
      result = receivedResult
    }

    let request1 = request as? EventsStartingIn30Minutes
    let request2 = EventsStartingIn30Minutes(now: timeService.now)
    XCTAssertEqual(request1, request2)

    if case let .success(events) = result {
      XCTAssertEqual(events, [event])
    } else {
      XCTFail()
    }
  }

  func testLoadEventsPerformReadError() throws {
    let error = NSError(domain: "test", code: 1)

    let timeService = TimeServiceProtocolMock()
    timeService.now = Date()

    let persistenceService = PersistenceServiceProtocolMock()
    persistenceService.performReadHandler = { _, completion in
      if let completion = completion as? ((Result<[Event], Error>) -> Void) {
        completion(.failure(error))
      }
    }

    var result: Result<[Event], Error>?
    let service = SoonService(timeService: timeService, persistenceService: persistenceService)
    service.loadEvents { receivedResult in
      result = receivedResult
    }

    if case let .failure(receivedError) = result {
      XCTAssertEqual(receivedError as NSError, error)
    } else {
      XCTFail()
    }
  }
}

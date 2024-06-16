@testable
import Fosdem
import XCTest

final class SearchResultViewModelTests: XCTestCase {
  func testDidChangeQuery() throws {
    let event = try Event.from(#"{"room":"D.apache.openoffice","people":[{"id":5243,"name":"Peter Kovacs"}],"start":{"minute":30,"hour":10},"id":11717,"track":"Apache OpenOffice","title":"State of Apache OpenOffice","date":634296600,"abstract":"<p>Time to look on the past year, and asses where is the Project.\nThis talk will summerize the 2020 reports, give an overview on Discussions and Activities within the Project.\nIf you want a quick look where the Project is and where we head, then Visit this Talk!</p>","duration":{"minute":45,"hour":0},"links":[{"name":"Video recording (WebM/VP9)","url":"https://video.fosdem.org/2021/D.apache.openoffice/openoffice_state.webm"},{"name":"Video recording (mp4)","url":"https://video.fosdem.org/2021/D.apache.openoffice/openoffice_state.mp4"},{"name":"Submit feedback","url":"https://submission.fosdem.org/feedback/11717.php"}],"attachments":[{"type":"slides","url":"https://fosdem.org/2021/schedule/event/openoffice_state/attachments/slides/4490/export/events/attachments/openoffice_state/slides/4490/Status_AOO_2020.odp"}]}"#)

    var read: Any?
    var readResult: Result<[Event], Error> = .success([])
    let persistenceService = PersistenceServiceProtocolMock()
    persistenceService.performReadHandler = { receivedRequest, completion in
      read = receivedRequest

      if let completion = completion as? ((Result<[Event], Error>) -> Void) {
        completion(readResult)
      }
    }

    let viewModel = SearchResultViewModel(persistenceService: persistenceService)

    viewModel.didChangeQuery("s")
    XCTAssertEqual(viewModel.configuration, SearchResultsConfiguration(configurationType: .noQuery, results: [], query: ""))
    XCTAssertNil(read)

    readResult = .failure(NSError(domain: "test", code: 1))
    viewModel.didChangeQuery("something")
    XCTAssertEqual(viewModel.configuration, SearchResultsConfiguration(configurationType: .failure, results: [], query: "something"))
    XCTAssertEqual(read as? GetEventsBySearch, GetEventsBySearch(query: "something"))

    readResult = .success([event])
    viewModel.didChangeQuery("something")
    XCTAssertEqual(viewModel.configuration, SearchResultsConfiguration(configurationType: .success, results: [event], query: "something"))
    XCTAssertEqual(read as? GetEventsBySearch, GetEventsBySearch(query: "something"))
  }
}

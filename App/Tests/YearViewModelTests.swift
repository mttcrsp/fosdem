import Combine
@testable
import Fosdem
import XCTest

final class YearViewModelTests: XCTestCase {
  func testDidLoadSuccess() throws {
    let tracks = [
      Track(name: "A", day: 2, date: Date()),
      Track(name: "B", day: 2, date: Date()),
      Track(name: "C", day: 1, date: Date()),
    ]

    let persistenceService = PersistenceServiceProtocolMock()
    persistenceService.performReadHandler = { _, completion in
      if let completion = completion as? ((Result<[Track], Error>) -> Void) {
        completion(.success(tracks))
      }
    }

    let viewModel = YearViewModel(persistenceService: persistenceService)
    viewModel.didLoad()
    XCTAssertEqual(viewModel.tracks, tracks)
    XCTAssertNotNil(persistenceService.performReadArgValues.first as? GetAllTracks)
  }

  func testDidLoadFailure() throws {
    let error = NSError(domain: "test", code: 1)

    let persistenceService = PersistenceServiceProtocolMock()
    persistenceService.performReadHandler = { _, completion in
      if let completion = completion as? ((Result<[Track], Error>) -> Void) {
        completion(.failure(error))
      }
    }

    let viewModel = YearViewModel(persistenceService: persistenceService)

    var cancellables: [AnyCancellable] = []
    let expectation = expectation(description: "Did fail")
    viewModel.didFail
      .sink { receivedError in
        XCTAssertEqual(receivedError as NSError, error)
        expectation.fulfill()
      }
      .store(in: &cancellables)

    viewModel.didLoad()
    wait(for: [expectation])
    XCTAssertNotNil(persistenceService.performReadArgValues.first as? GetAllTracks)
  }

  func testDidSelectTrack() throws {
    var completion: ((Result<[Event], Error>) -> Void)?
    let persistenceService = PersistenceServiceProtocolMock()
    persistenceService.performReadHandler = { _, receivedCompletion in
      if let receivedCompletion = receivedCompletion as? ((Result<[Event], Error>) -> Void) {
        completion = receivedCompletion
      }
    }

    let viewModel = YearViewModel(persistenceService: persistenceService)

    let track1 = Track(name: "A", day: 2, date: Date())
    viewModel.didSelectTrack(track1)
    XCTAssertEqual(persistenceService.performReadArgValues.last as? GetEventsByTrack, GetEventsByTrack(track: "A"))

    let event1 = try makeEvent1()
    completion?(.success([event1]))
    XCTAssertEqual(viewModel.events, [event1])

    let track2 = Track(name: "B", day: 2, date: Date())
    viewModel.didSelectTrack(track2)
    XCTAssertEqual(viewModel.events, [])
    XCTAssertEqual(persistenceService.performReadArgValues.last as? GetEventsByTrack, GetEventsByTrack(track: "B"))

    let event2 = try makeEvent2()
    completion?(.success([event2]))
    XCTAssertEqual(viewModel.events, [event2])

    let error = NSError(domain: "test", code: 1)
    viewModel.didSelectTrack(track1)

    var cancellables: [AnyCancellable] = []
    let expectation = expectation(description: "Did fail")
    viewModel.didFail
      .sink { receivedError in
        XCTAssertEqual(receivedError as NSError, error)
        expectation.fulfill()
      }
      .store(in: &cancellables)

    completion?(.failure(error))
    wait(for: [expectation])
  }

  private func makeEvent1() throws -> Event {
    try Event.from(#"{"room":"D.apache.openoffice","people":[{"id":5243,"name":"Peter Kovacs"}],"start":{"minute":30,"hour":10},"id":11717,"track":"Apache OpenOffice","title":"State of Apache OpenOffice","date":634296600,"abstract":"<p>Time to look on the past year, and asses where is the Project.\nThis talk will summerize the 2020 reports, give an overview on Discussions and Activities within the Project.\nIf you want a quick look where the Project is and where we head, then Visit this Talk!</p>","duration":{"minute":45,"hour":0},"links":[{"name":"Video recording (WebM/VP9)","url":"https://video.fosdem.org/2021/D.apache.openoffice/openoffice_state.webm"},{"name":"Video recording (mp4)","url":"https://video.fosdem.org/2021/D.apache.openoffice/openoffice_state.mp4"},{"name":"Submit feedback","url":"https://submission.fosdem.org/feedback/11717.php"}],"attachments":[{"type":"slides","url":"https://fosdem.org/2021/schedule/event/openoffice_state/attachments/slides/4490/export/events/attachments/openoffice_state/slides/4490/Status_AOO_2020.odp"}]}"#)
  }

  private func makeEvent2() throws -> Event {
    try Event.from(#"{"room":"D.apache.openoffice","people":[{"id":1275,"name":"Andrea Pescetti"}],"start":{"minute":15,"hour":11},"id":11694,"track":"Apache OpenOffice","title":"Rebuilding the Apache OpenOffice wiki","date":634299300,"abstract":"<p>The Apache OpenOffice wiki is the major source of information about OpenOffice for developers. A major restructuring is ongoing an d we will discuss what has been done and what remains to be done.</p>","duration":{"minute":45,"hour":0},"links":[{"name":"Video recording (WebM/VP9)","url":"https://video.fosdem.org/2021/D.apache.openoffice/openoffice_rebuilding_wiki.webm"},{"name":"Video recording (mp4)","url":"https://video.fosdem.org/2021/D.apache.openoffice/openoffice_rebuilding_wiki.mp4"},{"name":"Submit feedback","url":"https://submission.fosdem.org/feedback/11694.php"}],"attachments":[]}"#)
  }
}

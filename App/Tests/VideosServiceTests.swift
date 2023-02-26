@testable
import Fosdem
import XCTest

final class VideosServiceTests: XCTestCase {
  func testLoad() throws {
    let event1 = try makeEvent1()
    let event2 = try makeEvent2()
    let playbackService = makePlaybackService()
    let persistenceService = makePersistenceService(with: [.success([event1]), .success([event2])])

    let expectation = self.expectation(description: #function)
    var result: Result<VideosService.Videos, Error>?

    let videosService = VideosService(playbackService: playbackService, persistenceService: persistenceService)
    videosService.loadVideos { receivedResult in
      result = receivedResult
      expectation.fulfill()
    }

    waitForExpectations(timeout: 1)

    if case let .success(videos) = result {
      XCTAssertEqual(videos, VideosService.Videos(watching: [event2], watched: [event1]))
    } else {
      XCTFail()
    }

    let argsValues = persistenceService.performReadArgValues
    XCTAssertEqual(argsValues.count, 2)
    XCTAssertEqual(argsValues.last as? GetEventsByIdentifiers, .init(identifiers: [1, 2]))
    XCTAssertEqual(argsValues.first as? GetEventsByIdentifiers, .init(identifiers: [3, 4]))
  }

  func testLoadErrorWatched() throws {
    let event = try makeEvent1()
    let error = NSError(domain: "test", code: 1)
    let playbackService = makePlaybackService()
    let persistenceService = makePersistenceService(with: [.success([event]), .failure(error)])

    let expectation = self.expectation(description: #function)
    var result: Result<VideosService.Videos, Error>?

    let videosService = VideosService(playbackService: playbackService, persistenceService: persistenceService)
    videosService.loadVideos { receivedResult in
      result = receivedResult
      expectation.fulfill()
    }

    waitForExpectations(timeout: 1)

    if case let .failure(receivedError) = result {
      XCTAssertEqual(error, receivedError as NSError)
    } else {
      XCTFail()
    }
  }

  func testLoadErrorWatching() throws {
    let event = try makeEvent1()
    let error = NSError(domain: "test", code: 1)
    let playbackService = makePlaybackService()
    let persistenceService = makePersistenceService(with: [.failure(error), .success([event])])

    let expectation = self.expectation(description: #function)
    var result: Result<VideosService.Videos, Error>?

    let videosService = VideosService(playbackService: playbackService, persistenceService: persistenceService)
    videosService.loadVideos { receivedResult in
      result = receivedResult
      expectation.fulfill()
    }

    waitForExpectations(timeout: 1)

    if case let .failure(receivedError) = result {
      XCTAssertEqual(error, receivedError as NSError)
    } else {
      XCTFail()
    }
  }

  private func makePersistenceService(with results: [Result<[Event], Error>]) -> PersistenceServiceProtocolMock {
    var results = results
    let persistenceService = PersistenceServiceProtocolMock()
    persistenceService.performReadHandler = { _, completion in
      if let completion = completion as? ((Result<[Event], Error>) -> Void) {
        completion(results.removeFirst())
      }
    }
    return persistenceService
  }

  private func makePlaybackService() -> PlaybackServiceProtocolMock {
    PlaybackServiceProtocolMock(watching: [1, 2], watched: [3, 4])
  }

  private func makeEvent1() throws -> Event {
    try Event.from(#"{"room":"D.apache.openoffice","people":[{"id":5243,"name":"Peter Kovacs"}],"start":{"minute":30,"hour":10},"id":11717,"track":"Apache OpenOffice","title":"State of Apache OpenOffice","date":634296600,"abstract":"<p>Time to look on the past year, and asses where is the Project.\nThis talk will summerize the 2020 reports, give an overview on Discussions and Activities within the Project.\nIf you want a quick look where the Project is and where we head, then Visit this Talk!</p>","duration":{"minute":45,"hour":0},"links":[{"name":"Video recording (WebM/VP9)","url":"https://video.fosdem.org/2021/D.apache.openoffice/openoffice_state.webm"},{"name":"Video recording (mp4)","url":"https://video.fosdem.org/2021/D.apache.openoffice/openoffice_state.mp4"},{"name":"Submit feedback","url":"https://submission.fosdem.org/feedback/11717.php"}],"attachments":[{"type":"slides","url":"https://fosdem.org/2021/schedule/event/openoffice_state/attachments/slides/4490/export/events/attachments/openoffice_state/slides/4490/Status_AOO_2020.odp"}]}"#)
  }

  private func makeEvent2() throws -> Event {
    try Event.from(#"{"room":"D.apache.openoffice","people":[{"id":1275,"name":"Andrea Pescetti"}],"start":{"minute":15,"hour":11},"id":11694,"track":"Apache OpenOffice","title":"Rebuilding the Apache OpenOffice wiki","date":634299300,"abstract":"<p>The Apache OpenOffice wiki is the major source of information about OpenOffice for developers. A major restructuring is ongoing an d we will discuss what has been done and what remains to be done.</p>","duration":{"minute":45,"hour":0},"links":[{"name":"Video recording (WebM/VP9)","url":"https://video.fosdem.org/2021/D.apache.openoffice/openoffice_rebuilding_wiki.webm"},{"name":"Video recording (mp4)","url":"https://video.fosdem.org/2021/D.apache.openoffice/openoffice_rebuilding_wiki.mp4"},{"name":"Submit feedback","url":"https://submission.fosdem.org/feedback/11694.php"}],"attachments":[]}"#)
  }
}

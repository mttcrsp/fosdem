import Combine
@testable
import Fosdem
import XCTest

final class VideosViewModelTests: XCTestCase {
  func testDidDelete() throws {
    let event = try makeEvent1()
    let playbackService = PlaybackServiceProtocolMock()
    let dependencies = Dependencies(playbackService: playbackService)
    let viewModel = VideosViewModel(dependencies: dependencies)
    viewModel.didDelete(event)
    XCTAssertEqual(playbackService.setPlaybackPositionArgValues.map(\.0), [.beginning])
    XCTAssertEqual(playbackService.setPlaybackPositionArgValues.map(\.1), [event.id])
  }

  func testDidLoad() throws {
    let event1 = try makeEvent1()
    let event2 = try makeEvent2()

    var handler: (() -> Void)?
    let playbackService = PlaybackServiceProtocolMock()
    playbackService.addObserverHandler = { receivedHandler in
      handler = receivedHandler
      return NSObject()
    }

    let videosService = VideosServiceProtocolMock()
    videosService.loadVideosHandler = { completion in
      completion(.success(.init(watching: [event1], watched: [event2])))
    }

    let dependencies = Dependencies(playbackService: playbackService, videosService: videosService)
    let viewModel = VideosViewModel(dependencies: dependencies)

    XCTContext.runActivity(named: "Initial loading") { _ in
      viewModel.didLoad()
      XCTAssertEqual(viewModel.watchingEvents, [event1])
      XCTAssertEqual(viewModel.watchedEvents, [event2])
    }

    XCTContext.runActivity(named: "Success update") { _ in
      videosService.loadVideosHandler = { completion in
        completion(.success(.init(watching: [event2], watched: [event1])))
      }
      handler?()
      XCTAssertEqual(viewModel.watchingEvents, [event2])
      XCTAssertEqual(viewModel.watchedEvents, [event1])
    }

    XCTContext.runActivity(named: "Failure update") { _ in
      videosService.loadVideosHandler = { completion in
        completion(.failure(NSError(domain: "test", code: 1)))
      }

      let expectation = expectation(description: "didFail event is sent")
      var cancellables: [AnyCancellable] = []
      viewModel.didFail
        .sink { _ in expectation.fulfill() }
        .store(in: &cancellables)

      handler?()
      wait(for: [expectation])
      XCTAssertEqual(viewModel.watchingEvents, [event2])
      XCTAssertEqual(viewModel.watchedEvents, [event1])
    }
  }

  func testDidUnload() throws {
    let observer = NSObject()
    let playbackService = PlaybackServiceProtocolMock()
    playbackService.addObserverHandler = { _ in observer }

    let dependencies = Dependencies(playbackService: playbackService)
    let viewModel = VideosViewModel(dependencies: dependencies)
    viewModel.didLoad()
    viewModel.didUnload()
    XCTAssertEqual(playbackService.removeObserverArgValues as? [NSObject], [observer])
  }

  private struct Dependencies: VideosViewModel.Dependencies {
    var playbackService: PlaybackServiceProtocol = PlaybackServiceProtocolMock()
    var videosService: VideosServiceProtocol = VideosServiceProtocolMock()
  }

  private func makeEvent1() throws -> Event {
    try Event.from(#"{"room":"D.apache.openoffice","people":[{"id":5243,"name":"Peter Kovacs"}],"start":{"minute":30,"hour":10},"id":11717,"track":"Apache OpenOffice","title":"State of Apache OpenOffice","date":634296600,"abstract":"<p>Time to look on the past year, and asses where is the Project.\nThis talk will summerize the 2020 reports, give an overview on Discussions and Activities within the Project.\nIf you want a quick look where the Project is and where we head, then Visit this Talk!</p>","duration":{"minute":45,"hour":0},"links":[{"name":"Video recording (WebM/VP9)","url":"https://video.fosdem.org/2021/D.apache.openoffice/openoffice_state.webm"},{"name":"Video recording (mp4)","url":"https://video.fosdem.org/2021/D.apache.openoffice/openoffice_state.mp4"},{"name":"Submit feedback","url":"https://submission.fosdem.org/feedback/11717.php"}],"attachments":[{"type":"slides","url":"https://fosdem.org/2021/schedule/event/openoffice_state/attachments/slides/4490/export/events/attachments/openoffice_state/slides/4490/Status_AOO_2020.odp"}]}"#)
  }

  private func makeEvent2() throws -> Event {
    try Event.from(#"{"room":"D.apache.openoffice","people":[{"id":1275,"name":"Andrea Pescetti"}],"start":{"minute":15,"hour":11},"id":11694,"track":"Apache OpenOffice","title":"Rebuilding the Apache OpenOffice wiki","date":634299300,"abstract":"<p>The Apache OpenOffice wiki is the major source of information about OpenOffice for developers. A major restructuring is ongoing an d we will discuss what has been done and what remains to be done.</p>","duration":{"minute":45,"hour":0},"links":[{"name":"Video recording (WebM/VP9)","url":"https://video.fosdem.org/2021/D.apache.openoffice/openoffice_rebuilding_wiki.webm"},{"name":"Video recording (mp4)","url":"https://video.fosdem.org/2021/D.apache.openoffice/openoffice_rebuilding_wiki.mp4"},{"name":"Submit feedback","url":"https://submission.fosdem.org/feedback/11694.php"}],"attachments":[]}"#)
  }
}

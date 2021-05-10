@testable
import Fosdem
import SnapshotTesting
import XCTest

final class YearControllerTests: XCTestCase {
  private typealias TracksResult = Result<[Track], Error>
  private typealias EventsResult = Result<[Event], Error>

  private class Dependencies: YearController.Dependencies {
    var navigationService: NavigationServiceProtocol = NavigationServiceProtocolMock()

    var schedulerService: SchedulerServiceProtocol = {
      let schedulerService = SchedulerServiceProtocolMock()
      schedulerService.onMainQueueHandler = { block in block() }
      return schedulerService
    }()
  }

  func testAppearance() throws {
    let track1 = Track(name: "Ada", day: 1, date: Date())
    let track2 = Track(name: "LLVM", day: 2, date: Date())
    let persistenceService = PersistenceServiceProtocolMock()
    persistenceService.performReadHandler = { _, completion in
      if let completion = completion as? ((TracksResult) -> Void) {
        completion(.success([track1, track2]))
      }
    }

    let yearController = YearController(year: "2021", yearPersistenceService: persistenceService, dependencies: Dependencies())
    assertSnapshot(matching: yearController, as: .image(on: .iPhone8Plus))
  }

  func testLoadingTracksError() throws {
    let error = NSError(domain: "test", code: 1)
    let persistenceService = PersistenceServiceProtocolMock()
    persistenceService.performReadHandler = { _, completion in
      if let completion = completion as? ((TracksResult) -> Void) {
        completion(.failure(error))
      }
    }

    var recordedError: Error?
    var recordedViewController: UIViewController?

    let yearController = YearController(year: "2021", yearPersistenceService: persistenceService, dependencies: Dependencies())
    yearController.didError = { viewController, error in
      recordedViewController = viewController
      recordedError = error
    }

    assertSnapshot(matching: yearController, as: .image(on: .iPhone8Plus))
    XCTAssertEqual(recordedViewController, yearController)
    XCTAssertEqual(recordedError as NSError?, error)
  }

  func testLoadingEventsError() throws {
    let error = NSError(domain: "test", code: 1)
    let track1 = Track(name: "Ada", day: 1, date: Date())
    let track2 = Track(name: "LLVM", day: 2, date: Date())
    let persistenceService = PersistenceServiceProtocolMock()
    persistenceService.performReadHandler = { _, completion in
      if let completion = completion as? ((TracksResult) -> Void) {
        completion(.success([track1, track2]))
      }
    }

    var recordedError: Error?
    var recordedViewController: UIViewController?

    let yearController = YearController(year: "2021", yearPersistenceService: persistenceService, dependencies: Dependencies())
    yearController.didError = { viewController, error in
      recordedViewController = viewController
      recordedError = error
    }

    assertSnapshot(matching: yearController, as: .image(on: .iPhone8Plus))

    persistenceService.performReadHandler = { _, completion in
      if let completion = completion as? ((EventsResult) -> Void) {
        completion(.failure(error))
      }
    }

    let tracksViewController = TracksViewController()
    yearController.tracksViewController(tracksViewController, didSelect: track1)
    XCTAssertEqual(recordedViewController, yearController)
    XCTAssertEqual(recordedError as NSError?, error)
  }

  func testSelection() throws {
    var event: Event?
    let eventViewController = UIViewController()
    let navigationService = NavigationServiceProtocolMock()
    navigationService.makePastEventViewControllerHandler = { receivedEvent in
      event = receivedEvent
      return eventViewController
    }

    let dependencies = Dependencies()
    dependencies.navigationService = navigationService

    let track = Track(name: "Ada", day: 1, date: Date())
    let event1 = try makeEvent1()
    let event2 = try makeEvent2()

    let persistenceService = PersistenceServiceProtocolMock()
    persistenceService.performReadHandler = { _, completion in
      if let completion = completion as? ((EventsResult) -> Void) {
        completion(.success([event1, event2]))
      }
    }

    let tracksViewController = TracksViewController()
    let tracksArgs = try tracksViewController.fos_mockShow()

    let yearController = YearController(year: "2021", yearPersistenceService: persistenceService, dependencies: dependencies)
    yearController.tracksViewController(tracksViewController, didSelect: track)

    let eventsViewController = try XCTUnwrap(tracksArgs.vc as? EventsViewController)
    assertSnapshot(matching: eventsViewController, as: .image(on: .iPhone8Plus))

    let eventsArgs = try yearController.fos_mockShow()
    yearController.eventsViewController(eventsViewController, didSelect: event2)
    XCTAssertEqual(try XCTUnwrap(eventsArgs.vc), eventViewController)
    XCTAssertEqual(event, event2)
  }

  func testSearch() throws {
    var event: Event?
    let eventViewController = UIViewController()
    let navigationService = NavigationServiceProtocolMock()
    navigationService.makePastEventViewControllerHandler = { receivedEvent in
      event = receivedEvent
      return eventViewController
    }

    let dependencies = Dependencies()
    dependencies.navigationService = navigationService

    let persistenceService = PersistenceServiceProtocolMock()

    let track = Track(name: "Ada", day: 1, date: Date())
    persistenceService.performReadHandler = { _, completion in
      if let completion = completion as? ((TracksResult) -> Void) {
        completion(.success([track]))
      }
    }

    let yearController = YearController(year: "2021", yearPersistenceService: persistenceService, dependencies: dependencies)
    assertSnapshot(matching: yearController, as: .image(on: .iPhone8Plus))
    XCTAssertEqual(persistenceService.performReadCallCount, 1)

    persistenceService.performReadHandler = { _, completion in
      if let completion = completion as? ((EventsResult) -> Void) {
        completion(.success([]))
      }
    }

    let searchController = UISearchController()
    searchController.searchBar.text = ""
    yearController.updateSearchResults(for: searchController)
    XCTAssertEqual(persistenceService.performReadCallCount, 1)

    let resultsViewController = try XCTUnwrap(yearController.resultsViewController)
    assertSnapshot(matching: resultsViewController, as: .image(on: .iPhone8Plus))

    let event1 = try makeEvent1()
    let event2 = try makeEvent2()
    persistenceService.performReadHandler = { _, completion in
      if let completion = completion as? ((EventsResult) -> Void) {
        completion(.success([event1, event2]))
      }
    }

    searchController.searchBar.text = "something"
    yearController.updateSearchResults(for: searchController)
    XCTAssertEqual(persistenceService.performReadCallCount, 2)
    assertSnapshot(matching: resultsViewController, as: .image(on: .iPhone8Plus))

//    let tracksViewController = TracksViewController()
//    let tracksArgs = try tracksViewController.fos_mockShow()
//
//    let eventsViewController = try XCTUnwrap(tracksArgs.vc as? EventsViewController)
//    assertSnapshot(matching: eventsViewController, as: .image(on: .iPhone8Plus))
//
//    let eventsArgs = try yearController.fos_mockShow()
//    yearController.eventsViewController(eventsViewController, didSelect: event2)
//    XCTAssertEqual(try XCTUnwrap(eventsArgs.vc), eventViewController)
//    XCTAssertEqual(event, event2)
  }

  private func makeEvent1() throws -> Event {
    try Event.from(#"{"room":"D.apache.openoffice","people":[{"id":5243,"name":"Peter Kovacs"}],"start":{"minute":30,"hour":10},"id":11717,"track":"Apache OpenOffice","title":"State of Apache OpenOffice","date":634296600,"abstract":"<p>Time to look on the past year, and asses where is the Project.\nThis talk will summerize the 2020 reports, give an overview on Discussions and Activities within the Project.\nIf you want a quick look where the Project is and where we head, then Visit this Talk!</p>","duration":{"minute":45,"hour":0},"links":[{"name":"Video recording (WebM/VP9)","url":"https://video.fosdem.org/2021/D.apache.openoffice/openoffice_state.webm"},{"name":"Video recording (mp4)","url":"https://video.fosdem.org/2021/D.apache.openoffice/openoffice_state.mp4"},{"name":"Submit feedback","url":"https://submission.fosdem.org/feedback/11717.php"}],"attachments":[{"type":"slides","url":"https://fosdem.org/2021/schedule/event/openoffice_state/attachments/slides/4490/export/events/attachments/openoffice_state/slides/4490/Status_AOO_2020.odp"}]}"#)
  }

  private func makeEvent2() throws -> Event {
    try Event.from(#"{"room":"D.apache.openoffice","people":[{"id":1275,"name":"Andrea Pescetti"}],"start":{"minute":15,"hour":11},"id":11694,"track":"Apache OpenOffice","title":"Rebuilding the Apache OpenOffice wiki","date":634299300,"abstract":"<p>The Apache OpenOffice wiki is the major source of information about OpenOffice for developers. A major restructuring is ongoing an d we will discuss what has been done and what remains to be done.</p>","duration":{"minute":45,"hour":0},"links":[{"name":"Video recording (WebM/VP9)","url":"https://video.fosdem.org/2021/D.apache.openoffice/openoffice_rebuilding_wiki.webm"},{"name":"Video recording (mp4)","url":"https://video.fosdem.org/2021/D.apache.openoffice/openoffice_rebuilding_wiki.mp4"},{"name":"Submit feedback","url":"https://submission.fosdem.org/feedback/11694.php"}],"attachments":[]}"#)
  }
}

@testable
import Fosdem
import SnapshotTesting
import XCTest

final class EventsViewControllerTests: XCTestCase {
  private func makeDataSource() throws -> EventsViewControllerDataSourceMock {
    let event1 = try makeEvent1()
    let event2 = try makeEvent2()
    let dataSource = EventsViewControllerDataSourceMock()
    dataSource.eventsHandler = { _ in [event1, event2] }
    dataSource.eventsViewControllerHandler = { _, event in event.track }
    return dataSource
  }

  func testAppearance() throws {
    let title = [String](repeating: "title", count: 10).joined(separator: " ")
    let message = [String](repeating: "message", count: 10).joined(separator: " ")

    let eventsViewController = EventsViewController(style: .fos_insetGrouped)
    eventsViewController.view.tintColor = .fos_label
    eventsViewController.emptyBackgroundTitle = title
    eventsViewController.emptyBackgroundMessage = message
    assertSnapshot(matching: eventsViewController, as: .image(on: .iPhone8Plus))
    XCTAssertEqual(eventsViewController.emptyBackgroundTitle, title)
    XCTAssertEqual(eventsViewController.emptyBackgroundMessage, message)

    let dataSource = try makeDataSource()
    eventsViewController.dataSource = dataSource
    eventsViewController.reloadData()
    assertSnapshot(matching: eventsViewController, as: .image(on: .iPhone8Plus))
  }

  func testEvents() throws {
    let eventsViewController = EventsViewController(style: .fos_insetGrouped)

    let dataSource = try makeDataSource()
    eventsViewController.dataSource = dataSource

    let delegate = EventsViewControllerDelegateMock()
    eventsViewController.delegate = delegate

    let tableView = try XCTUnwrap(eventsViewController.tableView)
    for section in 0 ..< tableView.numberOfSections {
      for row in 0 ..< tableView.numberOfRows(inSection: section) {
        let indexPath = IndexPath(row: row, section: section)
        tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
      }
    }

    XCTAssertEqual(
      delegate.eventsViewControllerArgValues.map(\.1),
      [try makeEvent1(), try makeEvent2()]
    )
  }

  func testLive() throws {
    let liveDataSource = EventsViewControllerLiveDataSourceMock()
    liveDataSource.eventsViewControllerHandler = { _, _ in true }

    let dataSource = try makeDataSource()
    let eventsViewController = EventsViewController(style: .fos_insetGrouped)
    eventsViewController.view.tintColor = .fos_label
    eventsViewController.liveDataSource = liveDataSource
    eventsViewController.dataSource = dataSource
    assertSnapshot(matching: eventsViewController, as: .image(on: .iPhone8Plus))

    let originalMethod = try XCTUnwrap(class_getInstanceMethod(UIView.self, #selector(getter: UIView.window)))
    let swizzledMethod = try XCTUnwrap(class_getInstanceMethod(UIView.self, #selector(getter: UIView.fos_window)))
    method_exchangeImplementations(originalMethod, swizzledMethod)

    liveDataSource.eventsViewControllerHandler = { _, _ in false }
    // Ideally, this should be tested using `reloadLiveStatus`. Unfortunately,
    // though `reloadLiveStatus` cannot actually be tested with snapshot tests
    // as it relies on `-[UITableView indexPathsForVisibleRows]` which does not
    // report the correct values with the presentation mechanism used during
    // snapshots
    //
    //  eventsViewController.reloadLiveStatus()
    eventsViewController.reloadData()
    assertSnapshot(matching: eventsViewController, as: .image(on: .iPhone8Plus))

    let event2 = try makeEvent2()
    liveDataSource.eventsViewControllerHandler = { _, event in event == event2 }
    eventsViewController.reloadData()
    assertSnapshot(matching: eventsViewController, as: .image(on: .iPhone8Plus))

    method_exchangeImplementations(swizzledMethod, originalMethod)
  }

  func testFavoritesEventsSwipe() throws {
    let favoritesDataSource = EventsViewControllerFavoritesDataSourceMock()
    let favoritesDelegate = EventsViewControllerFavoritesDelegateMock()
    let dataSource = try makeDataSource()
    let event1 = try makeEvent1()
    let event2 = try makeEvent2()

    let eventsViewController = EventsViewController(style: .fos_insetGrouped)
    eventsViewController.favoritesDataSource = favoritesDataSource
    eventsViewController.favoritesDelegate = favoritesDelegate
    eventsViewController.dataSource = dataSource

    let tableView = try XCTUnwrap(eventsViewController.tableView)

    favoritesDataSource.eventsViewControllerHandler = { _, _ in false }

    let unfavoriteIndexPath = IndexPath(row: 0, section: 0)
    let unfavoriteConfiguration = tableView.delegate?.tableView?(tableView, trailingSwipeActionsConfigurationForRowAt: unfavoriteIndexPath)
    let unfavoriteAction = try XCTUnwrap(unfavoriteConfiguration?.actions.first)

    unfavoriteAction.handler(unfavoriteAction, UIView()) { _ in }
    XCTAssertEqual(
      favoritesDelegate.eventsViewControllerArgValues.map(\.1.id),
      [event1.id]
    )

    favoritesDataSource.eventsViewControllerHandler = { _, _ in true }

    let favoriteIndexPath = IndexPath(row: 0, section: 1)
    let favoriteConfiguration = tableView.delegate?.tableView?(tableView, trailingSwipeActionsConfigurationForRowAt: favoriteIndexPath)
    let favoriteAction = try XCTUnwrap(favoriteConfiguration?.actions.first)

    favoriteAction.handler(favoriteAction, UIView()) { _ in }
    XCTAssertEqual(
      favoritesDelegate.eventsViewControllerArgValues.map(\.1.id),
      [event1.id, event2.id]
    )
  }

  func testUpdates() throws {
    let event1 = try makeEvent1()
    let event2 = try makeEvent2()
    let dataSource = EventsViewControllerDataSourceMock()
    dataSource.eventsHandler = { _ in [event1, event2] }

    let eventsViewController = EventsViewController(style: .fos_insetGrouped)
    eventsViewController.dataSource = dataSource
    assertSnapshot(matching: eventsViewController, as: .image(on: .iPhone8Plus))

    eventsViewController.performBatchUpdates {
      eventsViewController.deleteEvent(at: 0)
      dataSource.eventsHandler = { _ in [event1] }
    }
    assertSnapshot(matching: eventsViewController, as: .image(on: .iPhone8Plus))

    eventsViewController.performBatchUpdates {
      eventsViewController.insertEvent(at: 0)
      dataSource.eventsHandler = { _ in [event2, event1] }
    }
    assertSnapshot(matching: eventsViewController, as: .image(on: .iPhone8Plus))
  }

  func testSelection() throws {
    let events = try (0 ... 100).map { index in
      try Event.from(
        """
        {"room":"D.apache.openoffice","people":[{"id":1275,"name":"Andrea Pescetti"}],"start":{"minute":15,"hour":11},"id":\(index),"track":"Apache OpenOffice","title":"\(index) Rebuilding the Apache OpenOffice wiki","date":634299300,"abstract":"<p>The Apache OpenOffice wiki is the major source of information about OpenOffice for developers. A major restructuring is ongoing an d we will discuss what has been done and what remains to be done.</p>","duration":{"minute":45,"hour":0},"links":[{"name":"Video recording (WebM/VP9)","url":"https://video.fosdem.org/2021/D.apache.openoffice/openoffice_rebuilding_wiki.webm"},{"name":"Video recording (mp4)","url":"https://video.fosdem.org/2021/D.apache.openoffice/openoffice_rebuilding_wiki.mp4"},{"name":"Submit feedback","url":"https://submission.fosdem.org/feedback/11694.php"}],"attachments":[]}
        """
      )
    }

    let dataSource = EventsViewControllerDataSourceMock()
    dataSource.eventsHandler = { _ in events }

    let originalMethod = try XCTUnwrap(class_getInstanceMethod(UITableView.self, #selector(UITableView.selectRow(at:animated:scrollPosition:))))
    let swizzledMethod = try XCTUnwrap(class_getInstanceMethod(UITableView.self, #selector(UITableView.fos_selectRow(at:animated:scrollPosition:))))
    method_exchangeImplementations(originalMethod, swizzledMethod)

    let eventsViewController = EventsViewController(style: .fos_insetGrouped)
    eventsViewController.dataSource = dataSource
    eventsViewController.select(try XCTUnwrap(events.last))
    XCTAssertEqual(UITableView.animated, true)
    XCTAssertEqual(UITableView.scrollPosition, .some(.none))
    XCTAssertEqual(UITableView.indexPath, IndexPath(row: 0, section: 100))

    UITableView.animated = nil
    UITableView.indexPath = nil
    UITableView.scrollPosition = nil

    eventsViewController.select(try XCTUnwrap(events.first))
    XCTAssertEqual(UITableView.animated, true)
    XCTAssertEqual(UITableView.scrollPosition, .some(.none))
    XCTAssertEqual(UITableView.indexPath, IndexPath(row: 0, section: 0))

    method_exchangeImplementations(swizzledMethod, originalMethod)
  }

  private func makeEvent1() throws -> Event {
    try Event.from(#"{"room":"D.apache.openoffice","people":[{"id":5243,"name":"Peter Kovacs"}],"start":{"minute":30,"hour":10},"id":11717,"track":"Apache OpenOffice","title":"State of Apache OpenOffice","date":634296600,"abstract":"<p>Time to look on the past year, and asses where is the Project.\nThis talk will summerize the 2020 reports, give an overview on Discussions and Activities within the Project.\nIf you want a quick look where the Project is and where we head, then Visit this Talk!</p>","duration":{"minute":45,"hour":0},"links":[{"name":"Video recording (WebM/VP9)","url":"https://video.fosdem.org/2021/D.apache.openoffice/openoffice_state.webm"},{"name":"Video recording (mp4)","url":"https://video.fosdem.org/2021/D.apache.openoffice/openoffice_state.mp4"},{"name":"Submit feedback","url":"https://submission.fosdem.org/feedback/11717.php"}],"attachments":[{"type":"slides","url":"https://fosdem.org/2021/schedule/event/openoffice_state/attachments/slides/4490/export/events/attachments/openoffice_state/slides/4490/Status_AOO_2020.odp"}]}"#)
  }

  private func makeEvent2() throws -> Event {
    try Event.from(#"{"room":"D.apache.openoffice","people":[{"id":1275,"name":"Andrea Pescetti"}],"start":{"minute":15,"hour":11},"id":11694,"track":"Apache OpenOffice","title":"Rebuilding the Apache OpenOffice wiki","date":634299300,"abstract":"<p>The Apache OpenOffice wiki is the major source of information about OpenOffice for developers. A major restructuring is ongoing an d we will discuss what has been done and what remains to be done.</p>","duration":{"minute":45,"hour":0},"links":[{"name":"Video recording (WebM/VP9)","url":"https://video.fosdem.org/2021/D.apache.openoffice/openoffice_rebuilding_wiki.webm"},{"name":"Video recording (mp4)","url":"https://video.fosdem.org/2021/D.apache.openoffice/openoffice_rebuilding_wiki.mp4"},{"name":"Submit feedback","url":"https://submission.fosdem.org/feedback/11694.php"}],"attachments":[]}"#)
  }
}

private extension UIView {
  private static var window = UIWindow()

  @objc var fos_window: UIWindow? {
    UIView.window
  }
}

private extension UITableView {
  static var scrollPosition: ScrollPosition?
  static var indexPath: IndexPath?
  static var animated: Bool?

  @objc func fos_selectRow(at indexPath: IndexPath?, animated: Bool, scrollPosition: ScrollPosition) {
    UITableView.scrollPosition = scrollPosition
    UITableView.indexPath = indexPath
    UITableView.animated = animated
  }
}

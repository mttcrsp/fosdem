@testable
import Fosdem
import SnapshotTesting
import XCTest

final class TracksViewControllerTestsTests: XCTestCase {
  private let date = Date()

  private let favoritesDataSource: TracksViewControllerFavoritesDataSourceMock = {
    let favoritesDataSource = TracksViewControllerFavoritesDataSourceMock()
    favoritesDataSource.tracksViewControllerHandler = { _, track in
      if let row = Int(track.name) {
        return row % 2 == 0
      } else {
        return false
      }
    }
    return favoritesDataSource
  }()

  private let indexDataSource: TracksViewControllerIndexDataSourceMock = {
    let indexDataSource = TracksViewControllerIndexDataSourceMock()
    indexDataSource.tracksViewControllerHandler = { _, section in section.description }
    return indexDataSource
  }()

  private lazy var dataSource: TracksViewControllerDataSourceMock = {
    let dataSource = TracksViewControllerDataSourceMock()
    dataSource.numberOfSectionsHandler = { _ in 2 }
    dataSource.tracksViewControllerHandler = { _, section in section + 2 }
    dataSource.tracksViewControllerTrackAtHandler = { _, indexPath in
      Track(name: indexPath.row.description, day: indexPath.section, date: self.date)
    }
    return dataSource
  }()

  func testAppearance() throws {
    let tracksViewController = TracksViewController(style: .fos_insetGrouped)
    tracksViewController.favoritesDataSource = favoritesDataSource
    tracksViewController.indexDataSource = indexDataSource
    tracksViewController.dataSource = dataSource
    assertSnapshot(matching: tracksViewController, as: .image(on: .iPhone8Plus))
  }

  func testEvents() throws {
    let delegate = TracksViewControllerDelegateMock()

    let tracksViewController = TracksViewController(style: .fos_insetGrouped)
    tracksViewController.favoritesDataSource = favoritesDataSource
    tracksViewController.indexDataSource = indexDataSource
    tracksViewController.dataSource = dataSource
    tracksViewController.delegate = delegate

    let tableView = try XCTUnwrap(tracksViewController.tableView)
    for section in 0 ..< tableView.numberOfSections {
      for row in 0 ..< tableView.numberOfRows(inSection: section) {
        let indexPath = IndexPath(row: row, section: section)
        tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
      }
    }

    XCTAssertEqual(
      delegate.tracksViewControllerArgValues.map(\.1),
      [
        Track(name: "0", day: 0, date: date),
        Track(name: "1", day: 0, date: date),
        Track(name: "0", day: 1, date: date),
        Track(name: "1", day: 1, date: date),
        Track(name: "2", day: 1, date: date),
      ]
    )
  }

  func testIndexEvents() throws {
    let indexDelegate = TracksViewControllerIndexDelegateMock()

    let tracksViewController = TracksViewController(style: .fos_insetGrouped)
    tracksViewController.favoritesDataSource = favoritesDataSource
    tracksViewController.indexDataSource = indexDataSource
    tracksViewController.indexDelegate = indexDelegate
    tracksViewController.dataSource = dataSource

    let tableView = try XCTUnwrap(tracksViewController.tableView)
    _ = tableView.dataSource?.tableView?(tableView, sectionForSectionIndexTitle: "1", at: 1)

    let predicate = NSPredicate { _, _ in
      indexDelegate.tracksViewControllerArgValues.map(\.1) == [1]
    }

    wait(for: [expectation(for: predicate, evaluatedWith: nil)], timeout: 2)
  }

  func testFavoritesEventsSwipe() throws {
    let favoritesDelegate = TracksViewControllerFavoritesDelegateMock()

    let tracksViewController = TracksViewController(style: .fos_insetGrouped)
    tracksViewController.favoritesDataSource = favoritesDataSource
    tracksViewController.favoritesDelegate = favoritesDelegate
    tracksViewController.indexDataSource = indexDataSource
    tracksViewController.dataSource = dataSource

    let tableView = try XCTUnwrap(tracksViewController.tableView)

    let unfavoriteIndexPath = IndexPath(row: 1, section: 1)
    let unfavoriteConfiguration = tableView.delegate?.tableView?(tableView, trailingSwipeActionsConfigurationForRowAt: unfavoriteIndexPath)
    let unfavoriteAction = try XCTUnwrap(unfavoriteConfiguration?.actions.first)

    unfavoriteAction.handler(unfavoriteAction, UIView()) { _ in }
    XCTAssertEqual(
      favoritesDelegate.tracksViewControllerDidUnfavoriteArgValues.map(\.1),
      [Track(name: "1", day: 1, date: date)]
    )

    let favoriteIndexPath = IndexPath(row: 2, section: 1)
    let favoriteConfiguration = tableView.delegate?.tableView?(tableView, trailingSwipeActionsConfigurationForRowAt: favoriteIndexPath)
    let favoriteAction = try XCTUnwrap(favoriteConfiguration?.actions.first)

    favoriteAction.handler(favoriteAction, UIView()) { _ in }
    XCTAssertEqual(
      favoritesDelegate.tracksViewControllerArgValues.map(\.1),
      [Track(name: "2", day: 1, date: date)]
    )
  }

  func testReloadData() throws {
    let dataSource = TracksViewControllerDataSourceMock()
    dataSource.numberOfSectionsHandler = { _ in 1 }
    dataSource.tracksViewControllerHandler = { _, _ in 1 }
    dataSource.tracksViewControllerTrackAtHandler = { _, indexPath in
      Track(name: indexPath.row.description, day: indexPath.section, date: self.date)
    }

    let tracksViewController = TracksViewController(style: .fos_insetGrouped)
    tracksViewController.dataSource = dataSource

    let tableView = try XCTUnwrap(tracksViewController.tableView)
    XCTAssertEqual(tableView.numberOfRows(inSection: 0), 1)

    dataSource.tracksViewControllerHandler = { _, _ in 2 }
    tableView.reloadData()
    XCTAssertEqual(tableView.numberOfRows(inSection: 0), 2)
  }

  func testUpdates() throws {
    let dataSource = TracksViewControllerDataSourceMock()
    dataSource.numberOfSectionsHandler = { _ in 1 }
    dataSource.tracksViewControllerHandler = { _, _ in 2 }
    dataSource.tracksViewControllerTrackAtHandler = { _, indexPath in
      Track(name: indexPath.row.description, day: indexPath.section, date: self.date)
    }

    let tracksViewController = TracksViewController(style: .fos_insetGrouped)
    tracksViewController.dataSource = dataSource
    assertSnapshot(matching: tracksViewController, as: .image(on: .iPhone8Plus))

    tracksViewController.performBatchUpdates {
      tracksViewController.deleteFavorite(at: 0)
      tracksViewController.insertFavorite(at: 1)
      tracksViewController.insertFavorite(at: 2)
      dataSource.tracksViewControllerHandler = { _, _ in 3 }
    }
    assertSnapshot(matching: tracksViewController, as: .image(on: .iPhone8Plus))

    tracksViewController.performBatchUpdates {
      tracksViewController.deleteFavoritesSection()
      dataSource.numberOfSectionsHandler = { _ in 0 }
      dataSource.tracksViewControllerHandler = { _, _ in 0 }
    }
    assertSnapshot(matching: tracksViewController, as: .image(on: .iPhone8Plus))

    tracksViewController.performBatchUpdates {
      tracksViewController.insertFavoritesSection()
      tracksViewController.insertFavorite(at: 0)
      dataSource.numberOfSectionsHandler = { _ in 1 }
      dataSource.tracksViewControllerHandler = { _, _ in 1 }
    }
    assertSnapshot(matching: tracksViewController, as: .image(on: .iPhone8Plus))
  }

  func testScroll() throws {
    let dataSource = TracksViewControllerDataSourceMock()
    dataSource.numberOfSectionsHandler = { _ in 1 }
    dataSource.tracksViewControllerHandler = { _, _ in 100 }
    dataSource.tracksViewControllerTrackAtHandler = { _, indexPath in
      Track(name: indexPath.row.description, day: indexPath.section, date: self.date)
    }

    let tracksViewController = TracksViewController(style: .fos_insetGrouped)
    tracksViewController.dataSource = dataSource
    tracksViewController.scrollToRow(at: IndexPath(row: 80, section: 0), at: .middle, animated: false)
    assertSnapshot(matching: tracksViewController, as: .image(on: .iPhone8Plus))
  }
}

@testable
import Fosdem
import SnapshotTesting
import XCTest

final class YearsViewControllerTests: XCTestCase {
  private func makeDataSource(with states: [YearDownloadState] = YearDownloadState.allCases) -> YearsViewControllerDataSourceMock {
    let dataSource = YearsViewControllerDataSourceMock()
    dataSource.numberOfYearsHandler = { _ in states.count }
    dataSource.yearsViewControllerHandler = { _, index in index }
    dataSource.yearsViewControllerDownloadStateAtHandler = { _, index in states[index] }
    return dataSource
  }

  func testAppearance() {
    let dataSource1 = makeDataSource(with: [.available, .inProgress, .completed])
    let dataSource2 = makeDataSource(with: [.inProgress, .completed, .inProgress])

    let yearsViewController = YearsViewController()
    yearsViewController.dataSource = dataSource1
    yearsViewController.view.tintColor = .fos_label
    assertSnapshot(matching: yearsViewController, as: .image(on: .iPhone8Plus))

    yearsViewController.dataSource = dataSource2
    yearsViewController.reloadDownloadState(at: 0)
    yearsViewController.reloadDownloadState(at: 1)
    yearsViewController.reloadDownloadState(at: 2)
    assertSnapshot(matching: yearsViewController, as: .image(on: .iPhone8Plus))

    if #available(iOS 13.0, *) {
      yearsViewController.overrideUserInterfaceStyle = .dark
      yearsViewController.reloadDownloadState(at: 0)
      yearsViewController.reloadDownloadState(at: 1)
      yearsViewController.reloadDownloadState(at: 2)
      assertSnapshot(matching: yearsViewController, as: .image(on: .iPhone8Plus))
    }
  }

  func testEvents() throws {
    let dataSource = makeDataSource()
    let delegate = YearsViewControllerDelegateMock()

    let yearsViewController = YearsViewController()
    yearsViewController.dataSource = dataSource
    yearsViewController.delegate = delegate

    let indexPath = IndexPath(row: 1, section: 0)
    let tableView = try XCTUnwrap(yearsViewController.tableView)
    tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)

    XCTAssertEqual(delegate.yearsViewControllerCallCount, 1)
    XCTAssertEqual(delegate.yearsViewControllerArgValues.first?.0, yearsViewController)
    XCTAssertEqual(delegate.yearsViewControllerArgValues.first?.1, 1)
  }

  func testAllowsSelection() throws {
    let yearsViewController = YearsViewController()

    let tableView = yearsViewController.view.findSubview(ofType: UITableView.self)
    XCTAssertEqual(tableView?.allowsSelection, true)
    XCTAssertEqual(yearsViewController.allowsSelection, true)

    yearsViewController.allowsSelection = false
    XCTAssertEqual(tableView?.allowsSelection, false)
    XCTAssertEqual(yearsViewController.allowsSelection, false)

    yearsViewController.allowsSelection = true
    XCTAssertEqual(tableView?.allowsSelection, true)
    XCTAssertEqual(yearsViewController.allowsSelection, true)
  }
}

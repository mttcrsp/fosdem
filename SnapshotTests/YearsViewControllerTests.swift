@testable
import Fosdem
import SnapshotTesting
import XCTest

final class YearsViewControllerTests: XCTestCase {
  private let dataSource: YearsViewControllerDataSourceMock = {
    let dataSource = YearsViewControllerDataSourceMock()
    dataSource.yearsViewControllerHandler = { _, index in index }
    dataSource.yearsViewControllerDownloadStateAtHandler = { _, index in YearDownloadState.allCases[index] }
    dataSource.numberOfYearsHandler = { _ in YearDownloadState.allCases.count }
    return dataSource
  }()

  func testAppearance() throws {
    let yearsViewController = YearsViewController()
    yearsViewController.dataSource = dataSource
    yearsViewController.view.tintColor = .fos_label
    assertSnapshot(matching: yearsViewController, as: .image(on: .iPhone8Plus))
  }

  func testEvents() throws {
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
}

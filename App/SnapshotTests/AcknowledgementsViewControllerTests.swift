@testable
import Fosdem
import SnapshotTesting
import XCTest

final class AcknowledgementsViewControllerTests: XCTestCase {
  private let dataSource = AcknowledgementsViewControllerDataSourceMock(acknowledgements: [
    .init(name: "1", url: URL(fileURLWithPath: "/1")),
    .init(name: "2", url: URL(fileURLWithPath: "/2")),
  ])

  func testAppearance() throws {
    let acknowledgementsViewController = AcknowledgementsViewController(style: .insetGrouped)
    acknowledgementsViewController.dataSource = dataSource
    assertSnapshot(matching: acknowledgementsViewController, as: .image(on: .iPhone8Plus))
  }

  func testEvents() throws {
    let delegate = AcknowledgementsViewControllerDelegateMock()

    let acknowledgementsViewController = AcknowledgementsViewController()
    acknowledgementsViewController.dataSource = dataSource
    acknowledgementsViewController.delegate = delegate

    let tableView = try XCTUnwrap(acknowledgementsViewController.tableView)
    for section in 0 ..< tableView.numberOfSections {
      for row in 0 ..< tableView.numberOfRows(inSection: section) {
        let indexPath = IndexPath(row: row, section: section)
        tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
      }
    }

    XCTAssertEqual(delegate.acknowledgementsViewControllerCallCount, 2)
    XCTAssertEqual(
      delegate.acknowledgementsViewControllerArgValues.map(\.0),
      [acknowledgementsViewController, acknowledgementsViewController]
    )
    XCTAssertEqual(
      delegate.acknowledgementsViewControllerArgValues.map(\.1),
      [dataSource.acknowledgements[0], dataSource.acknowledgements[1]]
    )
  }
}

@testable
import Fosdem
import SnapshotTesting
import XCTest

final class MoreViewControllerTests: XCTestCase {
  func testAppearance() throws {
    let moreViewController = MoreViewController(style: .fos_insetGrouped)
    moreViewController.view.tintColor = .fos_label
    assertSnapshot(matching: moreViewController, as: .image(on: .iPhone8Plus))
  }

  func testEvents() throws {
    let delegate = MoreViewControllerDelegateMock()

    let moreViewController = MoreViewController()
    moreViewController.delegate = delegate

    let tableView = try XCTUnwrap(moreViewController.tableView)
    for section in 0 ..< tableView.numberOfSections {
      for row in 0 ..< tableView.numberOfRows(inSection: section) {
        let indexPath = IndexPath(row: row, section: section)
        tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
      }
    }

    XCTAssertEqual(delegate.moreViewControllerCallCount, 10)
    XCTAssertEqual(
      delegate.moreViewControllerArgValues.map(\.0),
      [MoreViewController](repeating: moreViewController, count: 10)
    )
    XCTAssertEqual(
      delegate.moreViewControllerArgValues.map(\.1),
      [.years, .history, .devrooms, .transportation, .video, .code, .acknowledgements, .legal, .overrideTime, .generateDatabase]
    )
  }
}

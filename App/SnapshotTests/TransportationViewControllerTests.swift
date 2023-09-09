@testable
import Fosdem
import SnapshotTesting
import XCTest

final class TransportationViewControllerTests: XCTestCase {
  func testAppearance() throws {
    let transportationViewController = TransportationViewController(style: .insetGrouped)
    assertSnapshot(matching: transportationViewController, as: .image(on: .iPhone8Plus))
  }

  func testEvents() throws {
    let delegate = TransportationViewControllerDelegateMock()

    let transportationViewController = TransportationViewController()
    transportationViewController.delegate = delegate

    let tableView = try XCTUnwrap(transportationViewController.tableView)
    for section in 0 ..< tableView.numberOfSections {
      for row in 0 ..< tableView.numberOfRows(inSection: section) {
        let indexPath = IndexPath(row: row, section: section)
        tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
      }
    }

    XCTAssertEqual(delegate.transportationViewControllerCallCount, 8)
    XCTAssertEqual(
      delegate.transportationViewControllerArgValues.map(\.0),
      [TransportationViewController](repeating: transportationViewController, count: 8)
    )
    XCTAssertEqual(
      delegate.transportationViewControllerArgValues.map(\.1),
      [.appleMaps, .googleMaps, .bus, .shuttle, .train, .car, .plane, .taxi]
    )
  }
}

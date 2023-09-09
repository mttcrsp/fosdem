@testable
import Fosdem
import SnapshotTesting
import XCTest

final class ErrorViewControllerTests: XCTestCase {
  func testAppearance() throws {
    let errorViewController = ErrorViewController()
    errorViewController.view.tintColor = .label
    assertSnapshot(matching: errorViewController, as: .image(on: .iPhone8Plus))

    errorViewController.showsAppStoreButton = true
    assertSnapshot(matching: errorViewController, as: .image(on: .iPhone8Plus))
    XCTAssertTrue(errorViewController.showsAppStoreButton)
  }

  func testEvents() {
    let delegate = ErrorViewControllerDelegateMock()

    let errorViewController = ErrorViewController()
    errorViewController.delegate = delegate

    let appStoreButton = errorViewController.view.findSubview(ofType: UIControl.self, accessibilityIdentifier: "appstore")
    appStoreButton?.sendActions(for: .touchUpInside)

    XCTAssertEqual(delegate.errorViewControllerDidTapAppStoreArgValues, [errorViewController])
  }
}

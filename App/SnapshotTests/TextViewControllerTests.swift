@testable
import Fosdem
import SnapshotTesting
import XCTest

final class TextViewControllerTests: XCTestCase {
  func testAppearance() throws {
    let textViewController = TextViewController()
    textViewController.view.tintColor = .fos_label
    textViewController.attributedText = NSAttributedString(string: "something")
    assertSnapshot(matching: textViewController, as: .image(on: .iPhone8Plus))
  }

  func testAccessibilityIdentifier() {
    let textViewController = TextViewController()
    textViewController.view.tintColor = .fos_label
    textViewController.attributedText = NSAttributedString(string: "something")
    textViewController.accessibilityIdentifier = "1"

    var textView = textViewController.view.findSubview(ofType: UIView.self, accessibilityIdentifier: "1")
    XCTAssertNotNil(textView)

    textViewController.accessibilityIdentifier = "2"
    textView = textViewController.view.findSubview(ofType: UIView.self, accessibilityIdentifier: "2")
    XCTAssertNotNil(textView)
  }
}

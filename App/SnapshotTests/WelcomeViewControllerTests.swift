@testable
import Fosdem
import SnapshotTesting
import XCTest

final class WelcomeViewControllerTests: XCTestCase {
  func testAppearance() throws {
    let welcomeViewController = WelcomeViewController(year: 2021)
    welcomeViewController.view.tintColor = .label
    assertSnapshot(matching: welcomeViewController, as: .image(on: .iPhone8Plus))

    welcomeViewController.showsContinue = true
    assertSnapshot(matching: welcomeViewController, as: .image(on: .iPhone8Plus))

    welcomeViewController.showsContinue = false
    assertSnapshot(matching: welcomeViewController, as: .image(on: .iPhone8Plus))
  }

  func testEvents() throws {
    let delegate = WelcomeViewControllerDelegateMock()

    let welcomeViewController = WelcomeViewController(year: 2021)
    welcomeViewController.showsContinue = true
    welcomeViewController.delegate = delegate

    let continueButton = welcomeViewController.view.findSubview(ofType: UIButton.self, accessibilityIdentifier: "continue")
    continueButton?.sendActions(for: .touchUpInside)

    XCTAssertEqual(delegate.welcomeViewControllerDidTapContinueArgValues, [welcomeViewController])
  }
}

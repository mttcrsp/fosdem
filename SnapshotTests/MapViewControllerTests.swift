@testable
import Fosdem
import SnapshotTesting
import XCTest

final class MapViewControllerTests: XCTestCase {
  func testAppearance() throws {
    let mapViewController = MapViewController()
    XCTAssertNotNil(mapViewController.view.findSubview(ofType: UIView.self, accessibilityLabel: L10n.Map.location))
    assertSnapshot(matching: mapViewController, as: .image(on: .iPhone8Plus))

    mapViewController.setAuthorizationStatus(.authorizedWhenInUse)
    XCTAssertNotNil(mapViewController.view.findSubview(ofType: UIView.self, accessibilityLabel: L10n.Map.Location.disable))

    mapViewController.setAuthorizationStatus(.authorizedAlways)
    XCTAssertNotNil(mapViewController.view.findSubview(ofType: UIView.self, accessibilityLabel: L10n.Map.Location.disable))

    mapViewController.setAuthorizationStatus(.denied)
    XCTAssertNotNil(mapViewController.view.findSubview(ofType: UIView.self, accessibilityLabel: L10n.Map.Location.enable))

    mapViewController.setAuthorizationStatus(.restricted)
    XCTAssertNotNil(mapViewController.view.findSubview(ofType: UIView.self, accessibilityLabel: L10n.Map.Location.enable))
  }

  func testEvents() throws {
    let delegate = MapViewControllerDelegateMock()

    let mapViewController = MapViewController()
    mapViewController.delegate = delegate

    let locationButton = mapViewController.view.findSubview(ofType: UIControl.self, accessibilityIdentifier: "location")
    locationButton?.sendActions(for: .touchUpInside)
    XCTAssertEqual(delegate.mapViewControllerDidTapLocationArgValues, [mapViewController])

    let resetButton = mapViewController.view.findSubview(ofType: UIControl.self, accessibilityIdentifier: "reset")
    resetButton?.sendActions(for: .touchUpInside)
    XCTAssertEqual(delegate.mapViewControllerDidTapResetArgValues, [mapViewController])
  }
}

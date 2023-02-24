@testable
import Fosdem
import MapKit
import SnapshotTesting
import XCTest

final class MapViewControllerTests: XCTestCase {
  func testAppearance() throws {
    let mapViewController = MapViewController()

    // MKMapView will load data from the network and update its appearance
    // dynamically. This dynamic updates make snapshot testing impossible. Also,
    // on iOS 16.2, attempting to get a snapshot of a hierarchy that contains a
    // MKMapView leads to a crash in ERROR_CGDataProvider_BufferIsNotReadable.
    // To work around both of these issues, the MKMapView instance managed by
    // MapViewController is removed from the hierarchy.
    let mapView = try XCTUnwrap(mapViewController.view.findSubview(ofType: MKMapView.self))
    mapView.removeFromSuperview()

    XCTAssertNotNil(mapViewController.view.findSubview(ofType: UIView.self, accessibilityLabel: L10n.Map.location))
    assertSnapshot(matching: mapViewController, as: .image(on: .iPhone8Plus))

    mapViewController.setAuthorizationStatus(.authorizedWhenInUse)
    XCTAssertNotNil(mapViewController.view.findSubview(ofType: UIView.self, accessibilityLabel: L10n.Map.Location.disable))
    assertSnapshot(matching: mapViewController, as: .image(on: .iPhone8Plus))

    mapViewController.setAuthorizationStatus(.authorizedAlways)
    XCTAssertNotNil(mapViewController.view.findSubview(ofType: UIView.self, accessibilityLabel: L10n.Map.Location.disable))
    assertSnapshot(matching: mapViewController, as: .image(on: .iPhone8Plus))

    mapViewController.setAuthorizationStatus(.denied)
    XCTAssertNotNil(mapViewController.view.findSubview(ofType: UIView.self, accessibilityLabel: L10n.Map.Location.enable))
    assertSnapshot(matching: mapViewController, as: .image(on: .iPhone8Plus))

    mapViewController.setAuthorizationStatus(.restricted)
    XCTAssertNotNil(mapViewController.view.findSubview(ofType: UIView.self, accessibilityLabel: L10n.Map.Location.enable))
    assertSnapshot(matching: mapViewController, as: .image(on: .iPhone8Plus))
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

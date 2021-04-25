@testable
import Fosdem
import MapKit
import SnapshotTesting
import XCTest

final class MapViewControllerTests: XCTestCase {
  func testAppearance() throws {
    let mapViewController = MapViewController()

    // MKMapView will load data from the network and update its appearance
    // dynamically. To make sure that these updates do not interefere with
    // testing, the MKMapView instance managed by MapViewController is covered
    // by a view with a solid background color.
    let coverView = UIView()
    coverView.backgroundColor = .red
    coverView.translatesAutoresizingMaskIntoConstraints = false

    let mapView = try XCTUnwrap(mapViewController.view.findSubview(ofType: MKMapView.self))
    mapView.addSubview(coverView)

    NSLayoutConstraint.activate([
      coverView.topAnchor.constraint(equalTo: mapView.topAnchor),
      coverView.bottomAnchor.constraint(equalTo: mapView.bottomAnchor),
      coverView.leadingAnchor.constraint(equalTo: mapView.leadingAnchor),
      coverView.trailingAnchor.constraint(equalTo: mapView.trailingAnchor),
    ])

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

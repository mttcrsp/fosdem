import CoreLocation
import MapKit

protocol MapViewControllerDelegate: AnyObject {
  func mapViewController(_ mapViewController: MapViewController, didSelect building: Building)
  func mapViewControllerDidDeselectBuilding(_ mapViewController: MapViewController)
  func mapViewControllerDidTapLocation(_ mapViewController: MapViewController)
  func mapViewControllerDidTapReset(_ mapViewController: MapViewController)
}

final class MapViewController: UIViewController {
  weak var delegate: MapViewControllerDelegate?

  var buildings: [Building] = [] {
    didSet { didChangeBuildings() }
  }

  private(set) var selectedBuilding: Building? {
    didSet { didChangeSelectedBuilding() }
  }

  private lazy var controlsViewCompactConstraints = [
    controlsView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    controlsView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 16),
  ]

  private lazy var controlsViewRegularConstraints = [
    controlsView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    controlsView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor, constant: -32),
  ]

  private lazy var mapView = MKMapView()
  private lazy var controlsView = MapControlsView()

  override func viewDidLoad() {
    super.viewDidLoad()

    mapView.delegate = self
    mapView.showsCompass = false
    mapView.isPitchEnabled = false
    mapView.showsUserLocation = true
    #if targetEnvironment(macCatalyst)
    mapView.pointOfInterestFilter = .none
    #else
    mapView.showsPointsOfInterest = false
    #endif
    mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMarkerAnnotationView.reuseIdentifier)

    controlsView.delegate = self
    controlsView.translatesAutoresizingMaskIntoConstraints = false

    for subview in [mapView, controlsView] {
      view.addSubview(subview)
    }
  }

  override func updateViewConstraints() {
    if traitCollection.fos_hasRegularSizeClasses {
      NSLayoutConstraint.activate(controlsViewRegularConstraints)
      NSLayoutConstraint.deactivate(controlsViewCompactConstraints)
    } else {
      NSLayoutConstraint.activate(controlsViewCompactConstraints)
      NSLayoutConstraint.deactivate(controlsViewRegularConstraints)
    }

    super.updateViewConstraints()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    mapView.frame = view.bounds
  }

  override func didMove(toParent parent: UIViewController?) {
    super.didMove(toParent: parent)
    mapView.tintColor = parent?.view?.window?.tintColor
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

    if #available(iOS 12.0, *), traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
      for annotation in mapView.annotations {
        let annotationView = mapView.view(for: annotation) as? MKMarkerAnnotationView
        annotationView?.markerTintColor = mapView.tintColor
      }
    }
  }

  func setAuthorizationStatus(_ status: CLAuthorizationStatus) {
    controlsView.authorizationStatus = status
  }

  func resetCamera(animated: Bool) {
    let rect = preferredMapRect
    let region = MKCoordinateRegion(rect)
    let span = region.span
    let center = region.center

    let topLeftLatitude = center.latitude + span.latitudeDelta / 2
    let topLeftLongitude = center.longitude - span.longitudeDelta / 2
    let topLeftCoordinate = CLLocationCoordinate2D(latitude: topLeftLatitude, longitude: topLeftLongitude)
    let topLeft = MKMapPoint(topLeftCoordinate)

    let adjacent: CLLocationDistance
    if rect.size.height > rect.size.width {
      let bottomLeftLatitude = center.latitude - span.latitudeDelta / 2
      let bottomLeftLongitude = center.longitude - span.longitudeDelta / 2
      let bottomLeftCoordinate = CLLocationCoordinate2D(latitude: bottomLeftLatitude, longitude: bottomLeftLongitude)
      let bottomLeft = MKMapPoint(bottomLeftCoordinate)
      adjacent = topLeft.distance(to: bottomLeft) / 2
    } else {
      let topRightLatitude = center.latitude + span.latitudeDelta / 2
      let topRightLongitude = center.longitude + span.longitudeDelta / 2
      let topRightCoordinate = CLLocationCoordinate2D(latitude: topRightLatitude, longitude: topRightLongitude)
      let topRight = MKMapPoint(topRightCoordinate)
      adjacent = topLeft.distance(to: topRight) / 2
    }

    let distance = adjacent / tan(9 * .pi / 180)
    let camera = MKMapCamera(lookingAtCenter: region.center, fromDistance: distance, pitch: 0, heading: 334.30179164562668)
    mapView.setCamera(camera, animated: animated)
  }

  func deselectSelectedAnnotation() {
    for annotation in mapView.selectedAnnotations {
      mapView.deselectAnnotation(annotation, animated: true)
    }
  }

  private var preferredMapRect: MKMapRect {
    var rect: MKMapRect = .null
    for building in buildings {
      rect = rect.union(building.polygon.boundingMapRect)
    }
    return rect
  }

  private func didChangeBuildings() {
    let overlays = buildings.map { building in building.polygon }
    mapView.removeOverlays(mapView.overlays)
    mapView.addOverlays(overlays)

    mapView.removeAnnotations(mapView.annotations)
    for building in buildings {
      mapView.addAnnotation(building)
    }

    if #available(iOS 13.0, *) {
      let region = MKCoordinateRegion(preferredMapRect)
      let boundary = MKMapView.CameraBoundary(coordinateRegion: region)
      mapView.cameraBoundary = boundary
    }

    resetCamera(animated: false)
  }

  private func didChangeSelectedBuilding() {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }

      if let building = self.selectedBuilding {
        self.didSelectBuilding(building)
      } else {
        self.didDeselectBuilding()
      }
    }
  }

  private func didDeselectBuilding() {
    delegate?.mapViewControllerDidDeselectBuilding(self)
  }

  private func didSelectBuilding(_ building: Building) {
    if !UIAccessibility.isVoiceOverRunning {
      delegate?.mapViewController(self, didSelect: building)
    }
  }

  func setCenter(_ center: CLLocationCoordinate2D, animated: Bool) {
    mapView.setCenter(center, animated: animated)
  }

  func convertToMapPoint(_ coordinate: CLLocationCoordinate2D) -> CGPoint {
    mapView.convert(coordinate, toPointTo: mapView)
  }

  func convertToMapCoordinate(_ point: CGPoint) -> CLLocationCoordinate2D {
    mapView.convert(point, toCoordinateFrom: mapView)
  }
}

extension MapViewController: MKMapViewDelegate {
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    let renderer = MKPolygonRenderer(overlay: overlay)
    renderer.fillColor = mapView.tintColor.withAlphaComponent(0.3)
    renderer.strokeColor = mapView.tintColor
    renderer.lineWidth = 1
    return renderer
  }

  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    guard let building = annotation as? Building else { return nil }

    let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: MKMarkerAnnotationView.reuseIdentifier, for: annotation) as! MKMarkerAnnotationView
    annotationView.accessibilityLabel = L10n.Map.building(building.title ?? "")
    annotationView.accessibilityIdentifier = "building_\(building.glyph)"
    annotationView.markerTintColor = mapView.tintColor
    annotationView.glyphText = building.glyph
    return annotationView
  }

  func mapView(_: MKMapView, didSelect view: MKAnnotationView) {
    if let building = view.annotation as? Building {
      selectedBuilding = building
    }
  }

  func mapView(_: MKMapView, didDeselect view: MKAnnotationView) {
    if view.annotation is Building {
      selectedBuilding = nil
    }
  }
}

extension MapViewController: MapControlsViewDelegate {
  func controlsViewDidTapLocation(_: MapControlsView) {
    delegate?.mapViewControllerDidTapLocation(self)
  }

  func controlsViewDidTapReset(_: MapControlsView) {
    delegate?.mapViewControllerDidTapReset(self)
  }
}

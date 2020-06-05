import CoreLocation
import MapKit

protocol MapViewControllerDelegate: AnyObject {
    func mapViewController(_ mapViewController: MapViewController, didSelect building: Building)
    func mapViewControllerDidDeselectBuilding(_ mapViewController: MapViewController)
    func mapViewControllerDidTapLocation(_ mapViewController: MapViewController)
}

final class MapViewController: UIViewController {
    weak var delegate: MapViewControllerDelegate?

    var buildings: [Building] = [] {
        didSet { didChangeBuildings() }
    }

    private(set) var selectedBuilding: Building? {
        didSet { didChangeSelectedBuilding() }
    }

    private lazy var mapView = MKMapView()
    private lazy var controlsView = MapControlsView()
    private lazy var blurView = UIVisualEffectView()

    private weak var blueprintsViewController: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) {
            blurView.effect = UIBlurEffect(style: .systemUltraThinMaterial)
        }

        mapView.delegate = self
        mapView.showsCompass = false
        mapView.isPitchEnabled = false
        mapView.showsUserLocation = true
        mapView.showsPointsOfInterest = false

        if #available(iOS 11.0, *) {
            mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMarkerAnnotationView.reuseIdentifier)
        }

        controlsView.delegate = self
        controlsView.translatesAutoresizingMaskIntoConstraints = false

        for subview in [mapView, blurView, controlsView] {
            view.addSubview(subview)
        }

        view.addSubview(blurView)

        NSLayoutConstraint.activate([
            controlsView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 16),
            controlsView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mapView.frame = view.bounds
        blurView.frame.size.width = view.bounds.width
        blurView.frame.size.height = view.layoutMargins.top
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
        controlsView.setAuthorizationStatus(status)
    }

    func resetCamera(animated: Bool) {
        let coordinateRegion = preferredCoordinateRegion
        mapView.setRegion(coordinateRegion, animated: animated)
        mapView.camera.heading = 334.30179164562668
    }

    func deselectSelectedAnnotation() {
        for annotation in mapView.selectedAnnotations {
            mapView.deselectAnnotation(annotation, animated: true)
        }
    }

    private var preferredCoordinateRegion: MKCoordinateRegion {
        var boundingMapRect: MKMapRect = .null
        for building in buildings {
            boundingMapRect = boundingMapRect.union(building.polygon.boundingMapRect)
        }
        return MKCoordinateRegion(boundingMapRect)
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
            let region = preferredCoordinateRegion
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
        guard #available(iOS 11.0, *), let building = annotation as? Building else { return nil }

        let format = NSLocalizedString("map.building", comment: "")
        let string = String(format: format, building.title ?? "")

        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: MKMarkerAnnotationView.reuseIdentifier, for: annotation) as! MKMarkerAnnotationView
        annotationView.markerTintColor = mapView.tintColor
        annotationView.accessibilityLabel = string
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
    func controlsViewDidTapReset(_: MapControlsView) {
        resetCamera(animated: true)
    }

    func controlsViewDidTapLocation(_: MapControlsView) {
        delegate?.mapViewControllerDidTapLocation(self)
    }
}

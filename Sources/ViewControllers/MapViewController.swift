import MapKit

protocol MapViewControllerDelegate: AnyObject {
    func mapViewController(_ mapViewController: MapViewController, didSelect building: Building)
    func mapViewControllerDidDeselectBuilding(_ mapViewController: MapViewController)
}

final class MapViewController: UIViewController {
    weak var delegate: MapViewControllerDelegate?

    var buildings: [Building] = [] {
        didSet { buildingsDidChange() }
    }

    private lazy var mapView = MKMapView()

    private(set) var selectedBuilding: Building? {
        didSet { selectedBuildingChanged() }
    }

    func deselectSelectedAnnotation() {
        for annotation in mapView.selectedAnnotations {
            mapView.deselectAnnotation(annotation, animated: true)
        }
    }

    override func loadView() {
        view = mapView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        mapView.tintColor = .fos_label
        mapView.isPitchEnabled = false
        mapView.showsUserLocation = true
        mapView.showsPointsOfInterest = false
        mapView.setCamera(.university, animated: false)

        if #available(iOS 11.0, *) {
            mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMarkerAnnotationView.reuseIdentifier)
        }

        if #available(iOS 13.0, *) {
            mapView.cameraBoundary = MKMapView.CameraBoundary(coordinateRegion: .universityBoundary)
        }

        let tapAction = #selector(didTapMap(_:))
        let tapRecognizer = UITapGestureRecognizer(target: self, action: tapAction)
        mapView.addGestureRecognizer(tapRecognizer)
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

    @objc private func didTapMap(_ recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: recognizer.view)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)

        let origin = MKMapPoint(coordinate)
        let size = MKMapSize(width: .leastNonzeroMagnitude, height: .leastNonzeroMagnitude)
        let rect = MKMapRect(origin: origin, size: size)

        if let building = buildings.first(where: { building in building.polygon.intersects(rect) }) {
            mapView.selectAnnotation(building, animated: true)
        }
    }

    private func buildingsDidChange() {
        let overlays = buildings.map { building in building.polygon }
        mapView.removeOverlays(mapView.overlays)
        mapView.addOverlays(overlays)

        mapView.removeAnnotations(mapView.annotations)
        for building in buildings {
            mapView.addAnnotation(building)
        }
    }

    private func selectedBuildingChanged() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if let building = self.selectedBuilding {
                self.delegate?.mapViewController(self, didSelect: building)
            } else {
                self.delegate?.mapViewControllerDidDeselectBuilding(self)
            }
        }
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
        guard #available(iOS 11.0, *), let building = annotation as? Building else {
            return nil
        }

        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: MKMarkerAnnotationView.reuseIdentifier, for: annotation) as! MKMarkerAnnotationView
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

private extension MKMapCamera {
    static var university: MKMapCamera {
        let center = CLLocationCoordinate2D(latitude: 50.813246501032737, longitude: 4.381289567335247)
        return .init(lookingAtCenter: center, fromDistance: 1421.0375826379536, pitch: 0, heading: 334.30179164562668)
    }
}

private extension MKCoordinateRegion {
    static var universityBoundary: MKCoordinateRegion {
        let center = CLLocationCoordinate2D(latitude: 50.812996597684815, longitude: 4.38132229168761)
        let span = MKCoordinateSpan(latitudeDelta: 0.0050337033797305253, longitudeDelta: 0.0045694524231123523)
        return .init(center: center, span: span)
    }
}

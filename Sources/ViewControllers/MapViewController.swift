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

    var showsLocationButton: Bool {
        get { !locationButton.isHidden }
        set { locationButton.isHidden = !newValue }
    }

    private(set) var selectedBuilding: Building? {
        didSet { didChangeSelectedBuilding() }
    }

    private lazy var mapView = MKMapView()
    private lazy var resetButton = RoundedButton()
    private lazy var locationButton = RoundedButton()

    private weak var blueprintsViewController: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(mapView)
        mapView.delegate = self
        mapView.isPitchEnabled = false
        mapView.showsUserLocation = true
        mapView.showsPointsOfInterest = false

        if #available(iOS 11.0, *) {
            mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMarkerAnnotationView.reuseIdentifier)
        }

        if #available(iOS 13.0, *) {
            // Camera boundary can be used to prevent the user to navigating too
            // far away from the content of the map. No need to a reset button.
        } else {
            let resetAction = #selector(didTapReset)
            let resetImage = UIImage(named: "arrow.counterclockwise")
            resetButton.contentEdgeInsets = .zero
            resetButton.imageView?.contentMode = .center
            resetButton.setImage(resetImage, for: .normal)
            resetButton.addTarget(self, action: resetAction, for: .touchUpInside)
            view.addSubview(resetButton)
        }

        let locationAction = #selector(didTapLocation)
        let locationTitle = NSLocalizedString("map.location", comment: "")
        locationButton.setTitle(locationTitle, for: .normal)
        locationButton.addTarget(self, action: locationAction, for: .touchUpInside)
        view.addSubview(locationButton)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        mapView.frame = view.bounds

        locationButton.sizeToFit()
        locationButton.center.x = view.bounds.midX
        locationButton.frame.origin.y = view.layoutMargins.top + 5

        resetButton.bounds.size = CGSize(width: 40, height: 40)
        resetButton.frame.origin.y = locationButton.frame.minY
        if #available(iOS 11.0, *) {
            resetButton.frame.origin.x = view.safeAreaInsets.left + 5
        } else {
            resetButton.frame.origin.x = 5
        }
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

    func resetCamera() {
        mapView.setRegion(preferredCoordinateRegion, animated: true)
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

    private func setControlButtonsAlpha(to alpha: CGFloat) {
        for button in [resetButton, locationButton] {
            button.alpha = alpha
        }
    }

    @objc private func didTapReset() {
        resetCamera()
    }

    @objc private func didTapLocation() {
        delegate?.mapViewControllerDidTapLocation(self)
    }

    private func didChangeBuildings() {
        let overlays = buildings.map { building in building.polygon }
        mapView.removeOverlays(mapView.overlays)
        mapView.addOverlays(overlays)

        mapView.removeAnnotations(mapView.annotations)
        for building in buildings {
            mapView.addAnnotation(building)
        }

        let coordinateRegion = preferredCoordinateRegion
        mapView.setRegion(coordinateRegion, animated: false)
        mapView.camera.heading = 334.30179164562668

        if #available(iOS 13.0, *) {
            mapView.cameraBoundary = MKMapView.CameraBoundary(coordinateRegion: coordinateRegion)
        }
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
        guard !UIAccessibility.isVoiceOverRunning else { return }

        mapView.setCenter(building.coordinate, animated: true)

        delegate?.mapViewController(self, didSelect: building)
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

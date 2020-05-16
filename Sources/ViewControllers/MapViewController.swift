import MapKit

protocol MapViewControllerDelegate: AnyObject {
    func mapViewController(_ mapViewController: MapViewController, didSelect building: Building)
    func mapViewControllerDidDeselectBuilding(_ mapViewController: MapViewController)
    func mapViewControllerDidTapLocation(_ mapViewController: MapViewController)
}

final class MapViewController: UIViewController {
    weak var delegate: MapViewControllerDelegate?

    var buildings: [Building] = [] {
        didSet { buildingsDidChange() }
    }

    var showsLocationButton: Bool {
        get { !locationButton.isHidden }
        set { locationButton.isHidden = !newValue }
    }

    private(set) var selectedBuilding: Building? {
        didSet { selectedBuildingChanged() }
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

        let tapAction = #selector(didTapMap(_:))
        let tapRecognizer = UITapGestureRecognizer(target: self, action: tapAction)
        mapView.addGestureRecognizer(tapRecognizer)

        let locationAction = #selector(didTapLocation)
        let locationTitle = NSLocalizedString("map.location", comment: "")
        locationButton.setTitle(locationTitle, for: .normal)
        locationButton.addTarget(self, action: locationAction, for: .touchUpInside)
        view.addSubview(locationButton)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        mapView.frame = view.bounds

        if let blueprintsView = blueprintsViewController?.view {
            blueprintsView.frame = blueprintsFrame
        }

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

    func deselectSelectedAnnotation() {
        for annotation in mapView.selectedAnnotations {
            mapView.deselectAnnotation(annotation, animated: true)
        }
    }

    func addBlueprintsViewController(_ blueprintsViewController: UIViewController) {
        self.blueprintsViewController = blueprintsViewController

        addChild(blueprintsViewController)

        let blueprintsView: UIView = blueprintsViewController.view
        blueprintsView.backgroundColor = .fos_systemBackground
        blueprintsView.alpha = 0
        blueprintsView.layer.cornerRadius = 8
        blueprintsView.layer.shadowRadius = 8
        blueprintsView.layer.shadowOpacity = 0.2
        blueprintsView.layer.shadowOffset = .zero
        blueprintsView.layer.shadowColor = UIColor.black.cgColor
        view.addSubview(blueprintsView)

        let animator = UIViewPropertyAnimator(duration: 0.3, dampingRatio: 0.8)
        animator.addAnimations { [weak self] in
            self?.blueprintsViewController?.view.alpha = 1
            self?.setControlButtonsAlpha(to: 0)
        }
        animator.addCompletion { [weak self] _ in
            guard let self = self else { return }
            self.blueprintsViewController?.didMove(toParent: self)
        }
        animator.startAnimation()
    }

    func removeBlueprinsViewController() {
        blueprintsViewController?.willMove(toParent: nil)

        let animator = UIViewPropertyAnimator(duration: 0.3, dampingRatio: 0.8)
        animator.addAnimations { [weak self] in
            self?.blueprintsViewController?.view.alpha = 0
            self?.setControlButtonsAlpha(to: 1)
        }
        animator.addCompletion { [weak self] _ in
            self?.blueprintsViewController?.view.removeFromSuperview()
            self?.blueprintsViewController?.removeFromParent()
        }
        animator.startAnimation()
    }

    private var preferredCoordinateRegion: MKCoordinateRegion {
        var boundingMapRect: MKMapRect = .null
        for building in buildings {
            boundingMapRect = boundingMapRect.union(building.polygon.boundingMapRect)
        }
        return MKCoordinateRegion(boundingMapRect)
    }
    
    private var prefersVerticalBlueprintsLayout: Bool {
        view.bounds.width < view.bounds.height
    }

    private var blueprintsFrame: CGRect {
        var frame = CGRect()

        if traitCollection.horizontalSizeClass == .regular {
            frame.size = CGSize(width: 320, height: 320)
            frame.origin.x = view.layoutMargins.left
            frame.origin.y = 16
        } else if prefersVerticalBlueprintsLayout {
            frame.size.width = view.bounds.width - view.layoutMargins.left - view.layoutMargins.right
            frame.size.height = 200
            frame.origin.x = view.layoutMargins.left
            frame.origin.y = view.bounds.height - view.layoutMargins.bottom - frame.height - 32
        } else {
            frame.size.width = 300
            frame.size.height = view.bounds.height - view.layoutMargins.bottom - 48
            frame.origin.x = view.layoutMargins.left
            frame.origin.y = 16
        }
        return frame
    }

    private func setControlButtonsAlpha(to alpha: CGFloat) {
        for button in [resetButton, locationButton] {
            button.alpha = alpha
        }
    }

    @objc private func didTapReset() {
        mapView.setRegion(preferredCoordinateRegion, animated: true)
    }

    @objc private func didTapLocation() {
        delegate?.mapViewControllerDidTapLocation(self)
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

        let coordinateRegion = preferredCoordinateRegion
        mapView.setRegion(coordinateRegion, animated: false)
        if #available(iOS 13.0, *) {
            mapView.cameraBoundary = MKMapView.CameraBoundary(coordinateRegion: coordinateRegion)
        }
    }

    private func selectedBuildingChanged() {
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
        delegate?.mapViewController(self, didSelect: building)

        var center = mapView.convert(building.coordinate, toPointTo: mapView)
        if prefersVerticalBlueprintsLayout {
            center.y += blueprintsFrame.height / 2
        } else {
            center.x -= blueprintsFrame.width / 2
        }

        let centerCoordinates = mapView.convert(center, toCoordinateFrom: mapView)
        mapView.setCenter(centerCoordinates, animated: true)
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
            print(">>> attemping to display user location")
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

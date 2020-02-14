import MapKit

final class MapViewController: UIViewController {
    private lazy var mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.region = .university
        return mapView
    }()

    override func loadView() {
        view = mapView
    }
}

private extension MKCoordinateRegion {
    static var university: MKCoordinateRegion {
        .init(center: .university, span: .university)
    }
}

private extension CLLocationCoordinate2D {
    static var university: CLLocationCoordinate2D {
        .init(latitude: 50.813111288641892, longitude: 4.381678384974947)
    }
}

private extension MKCoordinateSpan {
    static var university: MKCoordinateSpan {
        .init(latitudeDelta: 0.0058347748283011924, longitudeDelta: 0.0075902626019512809)
    }
}

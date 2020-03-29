import MapKit

final class MapViewController: UIViewController {
    private lazy var mapView = MKMapView()
    private lazy var mapOverlays: [MKPolygon] = [.buildingK, .buildingF1, .buildingU, .buildingAW, .buildingH, .buildingJ]

    override func loadView() {
        view = mapView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        mapView.region = .university
        mapView.showsPointsOfInterest = false

        if #available(iOS 13.0, *) {
            mapView.cameraBoundary = MKMapView.CameraBoundary(coordinateRegion: .university)
        }

        #if DEBUG
            let tapAction = #selector(didTapMap(_:))
            let tapRecognizer = UITapGestureRecognizer(target: self, action: tapAction)
            mapView.addGestureRecognizer(tapRecognizer)
        #endif
    }

    #if DEBUG
        @objc private func didTapMap(_ recognizer: UITapGestureRecognizer) {
            let location = recognizer.location(in: recognizer.view)
            let coordinates = mapView.convert(location, toCoordinateFrom: mapView)
            print(coordinates)
        }
    #endif

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mapView.removeOverlays(mapView.overlays)
        mapView.addOverlays(mapOverlays)
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolygonRenderer(overlay: overlay)
        renderer.strokeColor = view.window?.tintColor
        renderer.lineWidth = 1
        return renderer
    }
}

private extension MKCoordinateRegion {
    static var university: MKCoordinateRegion {
        let center = CLLocationCoordinate2D(latitude: 50.813028067326343, longitude: 4.381335908547527)
        let span = MKCoordinateSpan(latitudeDelta: 0.0066549403022264642, longitudeDelta: 0.0060411691513593269)
        return .init(center: center, span: span)
    }
}

private extension MKPolygon {
    static let buildingK: MKPolygon = {
        var coordinates: [CLLocationCoordinate2D] = []
        coordinates.append(.init(latitude: 50.814458559625876, longitude: 4.381856876748685))
        coordinates.append(.init(latitude: 50.81460353376457, longitude: 4.382335633915915))
        coordinates.append(.init(latitude: 50.81507085881597, longitude: 4.381966559549568))
        coordinates.append(.init(latitude: 50.814929021679205, longitude: 4.381496602265003))
        return .init(coordinates: &coordinates, count: coordinates.count)
    }()

    static let buildingAW: MKPolygon = {
        var coordinates: [CLLocationCoordinate2D] = []
        coordinates.append(.init(latitude: 50.811981418430776, longitude: 4.380620569316875))
        coordinates.append(.init(latitude: 50.81212678134494, longitude: 4.3811021386389655))
        coordinates.append(.init(latitude: 50.81239391138743, longitude: 4.380901178776583))
        coordinates.append(.init(latitude: 50.81224834367137, longitude: 4.380419646773959))
        return .init(coordinates: &coordinates, count: coordinates.count)
    }()

    static let buildingH: MKPolygon = {
        var coordinates: [CLLocationCoordinate2D] = []
        coordinates.append(.init(latitude: 50.813223798056896, longitude: 4.380801222057073))
        coordinates.append(.init(latitude: 50.81294596061059, longitude: 4.381010402798182))
        coordinates.append(.init(latitude: 50.81251222314245, longitude: 4.379590300780109))
        coordinates.append(.init(latitude: 50.81278981477041, longitude: 4.379380876432748))
        return .init(coordinates: &coordinates, count: coordinates.count)
    }()

    static let buildingU: MKPolygon = {
        var coordinates: [CLLocationCoordinate2D] = []
        coordinates.append(.init(latitude: 50.81200835762422, longitude: 4.383510959060715))
        coordinates.append(.init(latitude: 50.81166069533526, longitude: 4.383780919599133))
        coordinates.append(.init(latitude: 50.81131812977074, longitude: 4.382669274122151))
        coordinates.append(.init(latitude: 50.81277202029037, longitude: 4.381560241928554))
        coordinates.append(.init(latitude: 50.81311025923219, longitude: 4.382658918191652))
        coordinates.append(.init(latitude: 50.81276225201435, longitude: 4.382925439188568))
        coordinates.append(.init(latitude: 50.81248346551246, longitude: 4.382010231859567))
        coordinates.append(.init(latitude: 50.81172697195379, longitude: 4.382592372685707))
        coordinates.append(.init(latitude: 50.81200903327877, longitude: 4.383510437885263))
        return .init(coordinates: &coordinates, count: coordinates.count)
    }()

    static let buildingF1: MKPolygon = {
        var coordinates: [CLLocationCoordinate2D] = []
        coordinates.append(.init(latitude: 50.81373415229331, longitude: 4.383174063448877))
        coordinates.append(.init(latitude: 50.81381977148237, longitude: 4.383109746685335))
        coordinates.append(.init(latitude: 50.813803330128536, longitude: 4.383055740242639))
        coordinates.append(.init(latitude: 50.813815738698025, longitude: 4.383047884759975))
        coordinates.append(.init(latitude: 50.81372499654387, longitude: 4.382755550982466))
        coordinates.append(.init(latitude: 50.8137724593839, longitude: 4.382719219375559))
        coordinates.append(.init(latitude: 50.813575377211464, longitude: 4.382087481438646))
        coordinates.append(.init(latitude: 50.81353008568385, longitude: 4.382122831110223))
        coordinates.append(.init(latitude: 50.81339518857885, longitude: 4.381684626127026))
        coordinates.append(.init(latitude: 50.81349011488106, longitude: 4.381613926783899))
        coordinates.append(.init(latitude: 50.81335960214619, longitude: 4.38118529212943))
        coordinates.append(.init(latitude: 50.81337076996496, longitude: 4.38117645471155))
        coordinates.append(.init(latitude: 50.81334812410748, longitude: 4.381104773433066))
        coordinates.append(.init(latitude: 50.813337576718, longitude: 4.3811136108510595))
        coordinates.append(.init(latitude: 50.81330965714622, longitude: 4.3810203269954116))
        coordinates.append(.init(latitude: 50.813163544448315, longitude: 4.381128830848439))
        coordinates.append(.init(latitude: 50.81312724886649, longitude: 4.381024254736701))
        coordinates.append(.init(latitude: 50.81309188391347, longitude: 4.381051257958092))
        coordinates.append(.init(latitude: 50.81312662842896, longitude: 4.381156325037438))
        coordinates.append(.init(latitude: 50.8130102588421, longitude: 4.381241993506478))
        coordinates.append(.init(latitude: 50.813038488812225, longitude: 4.381337732200336))
        coordinates.append(.init(latitude: 50.81303011288878, longitude: 4.381345587682887))
        coordinates.append(.init(latitude: 50.81305120780419, longitude: 4.381417268961343))
        coordinates.append(.init(latitude: 50.813060824600655, longitude: 4.381408922511071))
        coordinates.append(.init(latitude: 50.81310493741387, longitude: 4.381555443053799))
        coordinates.append(.init(latitude: 50.81310431697605, longitude: 4.381608958528773))
        coordinates.append(.init(latitude: 50.8131309957956, longitude: 4.381638416588373))
        coordinates.append(.init(latitude: 50.81321970485561, longitude: 4.381929033476837))
        coordinates.append(.init(latitude: 50.813235215760784, longitude: 4.381918232188269))
        coordinates.append(.init(latitude: 50.81321969429854, longitude: 4.381929088557541))
        coordinates.append(.init(latitude: 50.81323644303097, longitude: 4.381918780110709))
        coordinates.append(.init(latitude: 50.813270250639306, longitude: 4.382022355457309))
        coordinates.append(.init(latitude: 50.81325319175747, longitude: 4.382038063566711))
        coordinates.append(.init(latitude: 50.81328296725633, longitude: 4.382138202764253))
        coordinates.append(.init(latitude: 50.813313052897286, longitude: 4.382113658843309))
        coordinates.append(.init(latitude: 50.8135662362653, longitude: 4.3829292410001415))
        coordinates.append(.init(latitude: 50.81364129479584, longitude: 4.382876226130833))
        return .init(coordinates: &coordinates, count: coordinates.count)
    }()

    static let buildingJ: MKPolygon = {
        var coordinates: [CLLocationCoordinate2D] = []
        coordinates.append(.init(latitude: 50.81312006612282, longitude: 4.3794500930570734))
        coordinates.append(.init(latitude: 50.81310083604865, longitude: 4.379555631915167))
        coordinates.append(.init(latitude: 50.81308528164246, longitude: 4.379832845637907))
        coordinates.append(.init(latitude: 50.81317532556383, longitude: 4.3799323788311995))
        coordinates.append(.init(latitude: 50.81324232051986, longitude: 4.379989320726793))
        coordinates.append(.init(latitude: 50.81327736876875, longitude: 4.380005028835797))
        coordinates.append(.init(latitude: 50.81331024586328, longitude: 4.380010919376758))
        coordinates.append(.init(latitude: 50.81333878068125, longitude: 4.380009446741468))
        coordinates.append(.init(latitude: 50.81336359355231, longitude: 4.379998647416471))
        coordinates.append(.init(latitude: 50.81338747592824, longitude: 4.37997508525288))
        coordinates.append(.init(latitude: 50.81338840641013, longitude: 4.379973121739226))
        coordinates.append(.init(latitude: 50.81340639572389, longitude: 4.37994514166985))
        coordinates.append(.init(latitude: 50.813418802143076, longitude: 4.379917652478923))
        coordinates.append(.init(latitude: 50.81342779679494, longitude: 4.3798965447073215))
        coordinates.append(.init(latitude: 50.81344051336876, longitude: 4.37984696598798))
        coordinates.append(.init(latitude: 50.81344671657422, longitude: 4.379813586256091))
        coordinates.append(.init(latitude: 50.813451989298244, longitude: 4.379771370712888))
        coordinates.append(.init(latitude: 50.81345788234205, longitude: 4.379721791993461))
        coordinates.append(.init(latitude: 50.813458192502225, longitude: 4.37969233928888))
        coordinates.append(.init(latitude: 50.81346488283853, longitude: 4.3795474663380105))
        coordinates.append(.init(latitude: 50.81340174331581, longitude: 4.379464571706933))
        coordinates.append(.init(latitude: 50.81336452403468, longitude: 4.379428246704606))
        coordinates.append(.init(latitude: 50.81333878068125, longitude: 4.379401739270492))
        coordinates.append(.init(latitude: 50.81330342231723, longitude: 4.379373268322752))
        coordinates.append(.init(latitude: 50.81330245902035, longitude: 4.379372732478998))
        coordinates.append(.init(latitude: 50.813331924325894, longitude: 4.379352115585959))
        coordinates.append(.init(latitude: 50.81332230933347, longitude: 4.3793295351792665))
        coordinates.append(.init(latitude: 50.813463742570576, longitude: 4.379223505443605))
        coordinates.append(.init(latitude: 50.813419692822606, longitude: 4.379085625574959))
        coordinates.append(.init(latitude: 50.81344202436824, longitude: 4.379069426587591))
        coordinates.append(.init(latitude: 50.81342713667232, longitude: 4.379020829625489))
        coordinates.append(.init(latitude: 50.81343768212412, longitude: 4.379012484692595))
        coordinates.append(.init(latitude: 50.81339643078451, longitude: 4.378869148198191))
        coordinates.append(.init(latitude: 50.813100453027374, longitude: 4.379094197125539))
        coordinates.append(.init(latitude: 50.81311068839045, longitude: 4.379128558613843))
        coordinates.append(.init(latitude: 50.8130551692731, longitude: 4.379171755913575))
        coordinates.append(.init(latitude: 50.81304431357205, longitude: 4.379136412668345))
        coordinates.append(.init(latitude: 50.81280015436059, longitude: 4.379326033406784))
        coordinates.append(.init(latitude: 50.81284171639106, longitude: 4.379468388144375))
        coordinates.append(.init(latitude: 50.81286559903367, longitude: 4.37944924388654))
        coordinates.append(.init(latitude: 50.8129218541074, longitude: 4.379634945530711))
        coordinates.append(.init(latitude: 50.81303661454888, longitude: 4.379547078296184))
        coordinates.append(.init(latitude: 50.81302917063692, longitude: 4.37952597052481))
        coordinates.append(.init(latitude: 50.81311973815207, longitude: 4.379450866128707))
        return .init(coordinates: &coordinates, count: coordinates.count)
    }()
}

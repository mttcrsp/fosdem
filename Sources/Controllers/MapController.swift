import UIKit

final class MapController: UIViewController {
    private weak var mapViewController: MapViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        let mapViewController = makeMapViewController()
        addChild(mapViewController)
        view.addSubview(mapViewController.view)
        mapViewController.didMove(toParent: self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mapViewController?.view.frame = view.bounds
    }

    private func makeMapViewController() -> MapViewController {
        let mapViewController = MapViewController()
        mapViewController.delegate = self
        self.mapViewController = mapViewController
        return mapViewController
    }
}

extension MapController: MapViewControllerDelegate {
    func mapViewController(_ mapViewController: MapViewController, didSelect building: Building) {
        print(#function, mapViewController, building)
    }
}

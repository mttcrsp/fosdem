import UIKit

final class ApplicationController: UITabBarController {
    private let services: Services

    init(services: Services) {
        self.services = services
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        var viewControllers: [UIViewController] = []
        viewControllers.append(makeTracksController())
        viewControllers.append(makePlanController())
        viewControllers.append(makeMapViewController())
        viewControllers.append(makeMoreController())
        setViewControllers(viewControllers, animated: false)
    }
}

private extension ApplicationController {
    func makePlanController() -> PlanController {
        let planController = PlanController(services: services)
        planController.title = NSLocalizedString("plan.title", comment: "")
        return planController
    }

    func makeTracksController() -> TracksController {
        let tracksController = TracksController(services: services)
        tracksController.title = NSLocalizedString("tracks.title", comment: "")
        return tracksController
    }

    func makeMapViewController() -> MapViewController {
        let mapViewController = MapViewController()
        mapViewController.title = NSLocalizedString("map.title", comment: "")
        return mapViewController
    }

    func makeMoreController() -> MoreController {
        let moreController = MoreController(services: services)
        moreController.title = NSLocalizedString("more.title", comment: "")
        return moreController
    }
}

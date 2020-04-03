import StoreKit
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

    private var previouslySelectedViewController: String? {
        get { UserDefaults.standard.selectedViewController }
        set { UserDefaults.standard.selectedViewController = newValue }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self

        var viewControllers: [UIViewController] = []
        viewControllers.append(makeHomeController())
        viewControllers.append(makePlanController())
        viewControllers.append(makeMapController())
        viewControllers.append(makeMoreController())
        setViewControllers(viewControllers, animated: false)

        for (index, viewController) in viewControllers.enumerated() where String(describing: type(of: viewController)) == previouslySelectedViewController {
            selectedIndex = index
        }

        services.updateService.delegate = self
        services.updateService.detectUpdates()
    }
}

private extension ApplicationController {
    func makePlanController() -> PlanController {
        let planController = PlanController(services: services)
        planController.title = NSLocalizedString("plan.title", comment: "")

        if #available(iOS 13.0, *) {
            planController.tabBarItem.image = UIImage(systemName: "calendar")
        } else {
            planController.tabBarItem.image = UIImage(named: "calendar")
        }

        if #available(iOS 11.0, *) {
            planController.navigationBar.prefersLargeTitles = true
        }

        return planController
    }

    func makeHomeController() -> HomeController {
        let tracksController = HomeController(services: services)
        tracksController.title = NSLocalizedString("home.title", comment: "")

        if #available(iOS 13.0, *) {
            tracksController.tabBarItem.image = UIImage(systemName: "magnifyingglass")
        } else {
            tracksController.tabBarItem.image = UIImage(named: "magnifyingglass")
        }

        if #available(iOS 11.0, *) {
            tracksController.navigationBar.prefersLargeTitles = true
        }

        return tracksController
    }

    func makeMapController() -> MapController {
        let mapController = MapController()
        mapController.title = NSLocalizedString("map.title", comment: "")

        if #available(iOS 13.0, *) {
            mapController.tabBarItem.image = UIImage(systemName: "map")
        } else {
            mapController.tabBarItem.image = UIImage(named: "map")
        }

        return mapController
    }

    func makeMoreController() -> MoreController {
        let moreController = MoreController(services: services)
        moreController.title = NSLocalizedString("more.title", comment: "")

        if #available(iOS 13.0, *) {
            moreController.tabBarItem.image = UIImage(systemName: "ellipsis.circle")
        } else {
            moreController.tabBarItem.image = UIImage(named: "ellipsis.circle")
        }

        if #available(iOS 11.0, *) {
            moreController.navigationBar.prefersLargeTitles = true
        }

        return moreController
    }

    func makeUpdateViewController(withHandler handler: @escaping () -> Void) -> UIAlertController {
        let dismissTitle = NSLocalizedString("update.dismiss", comment: "")
        let dismissAction = UIAlertAction(title: dismissTitle, style: .cancel)

        let confirmTitle = NSLocalizedString("update.confirm", comment: "")
        let confirmAction = UIAlertAction(title: confirmTitle, style: .default) { _ in handler() }

        let alertTitle = NSLocalizedString("update.title", comment: "")
        let alertMessage = NSLocalizedString("update.message", comment: "")
        let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        alertController.addAction(confirmAction)
        alertController.addAction(dismissAction)
        return alertController
    }

    func makeStoreViewController() -> SKStoreProductViewController {
        let parameters = [SKStoreProductParameterITunesItemIdentifier: ""]
        let productViewController = SKStoreProductViewController()
        productViewController.delegate = self
        productViewController.loadProduct(withParameters: parameters)
        return productViewController
    }
}

extension ApplicationController: UITabBarControllerDelegate {
    func tabBarController(_: UITabBarController, didSelect viewController: UIViewController) {
        previouslySelectedViewController = String(describing: type(of: viewController))
    }
}

extension ApplicationController: SKStoreProductViewControllerDelegate {
    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true)
    }
}

extension ApplicationController: UpdateServiceDelegate {
    func updateServiceDidDetectUpdate(_: UpdateService) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let updateHandler: () -> Void = { [weak self] in self?.didTapUpdate() }
            let updateViewController = self.makeUpdateViewController(withHandler: updateHandler)
            self.present(updateViewController, animated: true)
        }
    }

    private func didTapUpdate() {
        let storeViewController = makeStoreViewController()
        present(storeViewController, animated: true)
    }
}

private extension UserDefaults {
    var selectedViewController: String? {
        get { string(forKey: .selectedViewControllerKey) }
        set { set(newValue, forKey: .selectedViewControllerKey) }
    }
}

private extension String {
    static var selectedViewControllerKey: String { #function }
}

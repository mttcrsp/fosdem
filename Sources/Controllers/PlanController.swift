import UIKit

final class PlanController: UINavigationController {
    private weak var planViewController: PlanViewController?

    private var observation: NSObjectProtocol?
    private var events: [Event] = []

    private let services: Services

    init(services: Services) {
        self.services = services
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var favoritesService: FavoritesService {
        services.favoritesService
    }

    private var persistenceService: PersistenceService {
        services.persistenceService
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 11.0, *) {
            navigationBar.prefersLargeTitles = true
        }

        viewControllers = [makePlanViewController()]

        reloadFavoriteEvents()
        observation = favoritesService.addObserverForEvents { [weak self] in
            self?.reloadFavoriteEvents()
        }
    }

    private func reloadFavoriteEvents() {
        persistenceService.events(withIdentifiers: favoritesService.eventsIdentifiers) { result in
            DispatchQueue.main.async { [weak self] in
                switch result {
                case let .success(events):
                    self?.events = events
                    self?.planViewController?.reloadData()
                case .failure:
                    self?.viewControllers = [ErrorController()]
                }
            }
        }
    }
}

extension PlanController: PlanViewControllerDataSource, PlanViewControllerDelegate {
    func events(in _: PlanViewController) -> [Event] {
        events
    }

    func planViewController(_ planViewController: PlanViewController, didSelect event: Event) {
        planViewController.show(EventController(event: event, services: services), sender: nil)
    }

    func planViewController(_: PlanViewController, didUnfavorite event: Event) {
        favoritesService.removeEvent(withIdentifier: event.id)
    }
}

private extension PlanController {
    func makePlanViewController() -> PlanViewController {
        let planViewController = PlanViewController()
        planViewController.title = NSLocalizedString("Plan", comment: "")
        planViewController.dataSource = self
        planViewController.delegate = self
        self.planViewController = planViewController

        if #available(iOS 11.0, *) {
            planViewController.navigationItem.largeTitleDisplayMode = .always
        }

        return planViewController
    }
}

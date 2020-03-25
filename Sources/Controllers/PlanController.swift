import UIKit

final class PlanController: UINavigationController {
    private weak var planViewController: EventsViewController?

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

        viewControllers = [makePlanViewController()]

        reloadFavoriteEvents()
        observation = favoritesService.addObserverForEvents { [weak self] in
            self?.reloadFavoriteEvents()
        }
    }

    private func reloadFavoriteEvents() {
        let identifiers = favoritesService.eventsIdentifiers
        let operation = EventsForIdentifiers(identifiers: identifiers)

        persistenceService.performRead(operation) { result in
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

extension PlanController: EventsViewControllerDataSource, EventsViewControllerDelegate, EventsViewControllerFavoritesDataSource, EventsViewControllerFavoritesDelegate {
    func events(in _: EventsViewController) -> [Event] {
        events
    }

    func eventsViewController(_ planViewController: EventsViewController, didSelect event: Event) {
        planViewController.show(makeEventViewController(for: event), sender: nil)
    }

    func eventsViewController(_: EventsViewController, canFavorite event: Event) -> Bool {
        !favoritesService.contains(event)
    }

    func eventsViewController(_: EventsViewController, didFavorite event: Event) {
        favoritesService.addEvent(withIdentifier: event.id)
    }

    func eventsViewController(_: EventsViewController, didUnfavorite event: Event) {
        favoritesService.removeEvent(withIdentifier: event.id)
    }
}

private extension PlanController {
    func makeEventViewController(for event: Event) -> EventController {
        let eventViewController = EventController(event: event, favoritesService: favoritesService)
        eventViewController.hidesBottomBarWhenPushed = true
        return eventViewController
    }

    func makePlanViewController() -> EventsViewController {
        let planViewController = EventsViewController(style: .grouped)
        planViewController.emptyBackgroundText = NSLocalizedString("plan.empty", comment: "")
        planViewController.title = NSLocalizedString("plan.title", comment: "")
        planViewController.favoritesDataSource = self
        planViewController.favoritesDelegate = self
        planViewController.dataSource = self
        planViewController.delegate = self
        self.planViewController = planViewController

        if #available(iOS 11.0, *) {
            planViewController.navigationItem.largeTitleDisplayMode = .always
        }

        return planViewController
    }
}

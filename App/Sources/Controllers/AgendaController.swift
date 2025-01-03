import UIKit

final class AgendaController: UIViewController {
  typealias Dependencies = HasFavoritesService & HasNavigationService & HasPersistenceService & HasTimeService

  var didError: ((AgendaController, Error) -> Void)?

  private weak var agendaViewController: EventsViewController?
  private weak var eventViewController: UIViewController?

  private weak var rootViewController: UIViewController? {
    didSet { didChangeRootViewController(from: oldValue, to: rootViewController) }
  }

  private var observations: [NSObjectProtocol] = []
  private var events: [Event] = []

  private let dependencies: Dependencies

  init(dependencies: Dependencies) {
    self.dependencies = dependencies
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private var isMissingSecondaryViewController: Bool {
    eventViewController == nil
  }

  func didSelectTab() {
    if traitCollection.horizontalSizeClass == .compact {
      agendaViewController?.navigationController?.popToRootViewController(animated: true)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    reloadFavoriteEvents(animated: false)
    observations = [
      dependencies.favoritesService.addObserverForEvents { [weak self] in
        self?.reloadFavoriteEvents(animated: true)
      },
      dependencies.timeService.addObserver { [weak self] in
        self?.reloadLiveStatus()
      },
    ]
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass, isMissingSecondaryViewController {
      preselectFirstEvent()
    }
  }
}

private extension AgendaController {
  func preselectFirstEvent() {
    if let event = events.first, traitCollection.horizontalSizeClass == .regular {
      let eventViewController = makeEventViewController(for: event)
      let navigationController = UINavigationController(rootViewController: eventViewController)
      agendaViewController?.showDetailViewController(navigationController, sender: nil)
      agendaViewController?.select(event)
    }
  }

  func reloadLiveStatus() {
    agendaViewController?.reloadLiveStatus()
  }

  func reloadFavoriteEvents(animated: Bool) {
    let identifiers = dependencies.favoritesService.eventsIdentifiers

    if identifiers.isEmpty, !(rootViewController is UINavigationController) {
      rootViewController = makeAgendaNavigationController()
    } else if !identifiers.isEmpty, !(rootViewController is UISplitViewController) {
      let agendaSplitViewController = UISplitViewController()
      agendaSplitViewController.viewControllers = [makeAgendaNavigationController()]
      agendaSplitViewController.preferredPrimaryColumnWidthFraction = 0.4
      agendaSplitViewController.preferredDisplayMode = .oneBesideSecondary
      agendaSplitViewController.maximumPrimaryColumnWidth = 375
      rootViewController = agendaSplitViewController
    }

    let operation = GetEventsByIdentifiers(identifiers: identifiers)
    dependencies.persistenceService.performRead(operation) { result in
      DispatchQueue.main.async { [weak self] in
        guard let self else { return }

        switch result {
        case let .failure(error):
          didError?(self, error)
        case let .success(events):
          loadingDidSucceed(with: events, animated: animated)
        }
      }
    }
  }

  private func loadingDidSucceed(with events: [Event], animated: Bool) {
    if animated {
      var oldEvents = self.events
      let newEvents = events
      let deletesEvents = Set(oldEvents).subtracting(newEvents)
      let insertsEvents = Set(newEvents).subtracting(oldEvents)

      agendaViewController?.beginUpdates()

      self.events = newEvents
      for (index, event) in oldEvents.enumerated().reversed() where deletesEvents.contains(event) {
        agendaViewController?.deleteEvent(at: index)
        oldEvents.remove(at: index)
      }
      for (index, event) in newEvents.enumerated() where insertsEvents.contains(event) {
        agendaViewController?.insertEvent(at: index)
        oldEvents.insert(event, at: index)
      }

      agendaViewController?.endUpdates()
    } else {
      self.events = events
      agendaViewController?.reloadData()
    }

    var didDeleteSelectedEvent = false
    if let selectedEventID = eventViewController?.fos_eventID, !events.contains(where: { event in event.id == selectedEventID }) {
      didDeleteSelectedEvent = true
    }

    if didDeleteSelectedEvent || isMissingSecondaryViewController {
      preselectFirstEvent()
    }
  }

  func didChangeRootViewController(from oldViewController: UIViewController?, to newViewController: UIViewController?) {
    if let viewController = oldViewController {
      viewController.willMove(toParent: nil)
      viewController.view.removeFromSuperview()
      viewController.removeFromParent()
    }

    if let viewController = newViewController {
      addChild(viewController)
      view.addSubview(viewController.view)
      viewController.view.translatesAutoresizingMaskIntoConstraints = false
      viewController.didMove(toParent: self)

      NSLayoutConstraint.activate([
        viewController.view.topAnchor.constraint(equalTo: view.topAnchor),
        viewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        viewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        viewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      ])
    }
  }
}

extension AgendaController: EventsViewControllerDataSource, EventsViewControllerDelegate {
  func events(in _: EventsViewController) -> [Event] {
    events
  }

  func eventsViewController(_: EventsViewController, captionFor event: Event) -> String? {
    [event.formattedStart, event.room, event.formattedTrack].compactMap { $0 }.joined(separator: " - ")
  }

  func eventsViewController(_ eventsViewController: EventsViewController, didSelect event: Event) {
    guard !(eventViewController?.fos_eventID == event.id && traitCollection.horizontalSizeClass == .regular) else { return }
    
    let eventViewController = makeEventViewController(for: event)
    let navigationController = UINavigationController(rootViewController: eventViewController)
    eventsViewController.showDetailViewController(navigationController, sender: nil)
    UIAccessibility.post(notification: .screenChanged, argument: eventViewController.view)
  }
}

extension AgendaController: EventsViewControllerFavoritesDataSource, EventsViewControllerFavoritesDelegate {
  func eventsViewController(_: EventsViewController, canFavorite event: Event) -> Bool {
    !dependencies.favoritesService.contains(event)
  }

  func eventsViewController(_: EventsViewController, didFavorite event: Event) {
    dependencies.favoritesService.addEvent(withIdentifier: event.id)
  }

  func eventsViewController(_: EventsViewController, didUnfavorite event: Event) {
    dependencies.favoritesService.removeEvent(withIdentifier: event.id)
  }
}

extension AgendaController: EventsViewControllerLiveDataSource {
  func eventsViewController(_ eventsViewController: EventsViewController, shouldShowLiveIndicatorFor event: Event) -> Bool {
    eventsViewController == agendaViewController && event.isLive(at: dependencies.timeService.now)
  }
}

private extension AgendaController {
  func makeAgendaNavigationController() -> UINavigationController {
    let agendaViewController = EventsViewController(style: .grouped)
    agendaViewController.emptyBackgroundMessage = L10n.Agenda.Empty.message
    agendaViewController.emptyBackgroundTitle = L10n.Agenda.Empty.title
    agendaViewController.title = L10n.Agenda.title
    agendaViewController.navigationItem.largeTitleDisplayMode = .always
    agendaViewController.favoritesDataSource = self
    agendaViewController.favoritesDelegate = self
    agendaViewController.liveDataSource = self
    agendaViewController.dataSource = self
    agendaViewController.delegate = self
    self.agendaViewController = agendaViewController

    let agendaNavigationController = UINavigationController(rootViewController: agendaViewController)
    agendaNavigationController.navigationBar.prefersLargeTitles = true
    return agendaNavigationController
  }

  func makeEventViewController(for event: Event) -> UIViewController {
    let eventViewController = dependencies.navigationService.makeEventViewController(for: event)
    eventViewController.fos_eventID = event.id
    self.eventViewController = eventViewController
    return eventViewController
  }
}

private extension UIViewController {
  private static var eventIDKey = 0

  var fos_eventID: Int? {
    get { objc_getAssociatedObject(self, &UIViewController.eventIDKey) as? Int }
    set { objc_setAssociatedObject(self, &UIViewController.eventIDKey, newValue as Int?, .OBJC_ASSOCIATION_COPY_NONATOMIC) }
  }
}

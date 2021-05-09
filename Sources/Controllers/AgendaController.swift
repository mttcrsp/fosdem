import UIKit

final class AgendaController: UIViewController {
  #if DEBUG
  typealias Dependencies = HasNavigationService & HasFavoritesService & HasPersistenceService & HasLiveService & HasDebugService
  #else
  typealias Dependencies = HasNavigationService & HasFavoritesService & HasPersistenceService & HasLiveService
  #endif

  var didError: ((AgendaController, Error) -> Void)?

  private weak var agendaViewController: EventsViewController?
  private weak var soonViewController: EventsViewController?
  private weak var eventViewController: UIViewController?

  private weak var rootViewController: UIViewController? {
    didSet { didChangeRootViewController(from: oldValue, to: rootViewController) }
  }

  private var observations: [NSObjectProtocol] = []
  private var eventsStartingSoon: [Event] = []
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

  private var now: Date {
    #if DEBUG
    return dependencies.debugService.now
    #else
    return Date()
    #endif
  }

  func popToRootViewController() {
    if traitCollection.horizontalSizeClass == .compact {
      agendaViewController?.navigationController?.popToRootViewController(animated: true)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    reloadFavoriteEvents()
    observations = [
      dependencies.favoritesService.addObserverForEvents { [weak self] identifier in
        self?.reloadFavoriteEvents(forUpdateToEventWithIdentifier: identifier)
      },
      dependencies.liveService.addObserver { [weak self] in
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

  private func reloadLiveStatus() {
    agendaViewController?.reloadLiveStatus()
  }

  private func reloadFavoriteEvents(forUpdateToEventWithIdentifier identifier: Int? = nil) {
    let identifiers = dependencies.favoritesService.eventsIdentifiers

    if identifiers.isEmpty, !(rootViewController is UINavigationController) {
      rootViewController = makeAgendaNavigationController()
    } else if !identifiers.isEmpty, !(rootViewController is UISplitViewController) {
      rootViewController = makeAgendaSplitViewController()
    }

    let operation = EventsForIdentifiers(identifiers: identifiers)
    dependencies.persistenceService.performRead(operation) { result in
      DispatchQueue.main.async { [weak self] in
        switch result {
        case let .failure(error):
          self?.loadingDidFail(with: error)
        case let .success(events):
          self?.loadingDidSucceed(with: events, updatedEventIdentifier: identifier)
        }
      }
    }
  }

  private func loadingDidFail(with error: Error) {
    didError?(self, error)
  }

  private func loadingDidSucceed(with events: [Event], updatedEventIdentifier: Int?) {
    if let id = updatedEventIdentifier {
      let oldEvents = self.events
      let newEvents = events

      agendaViewController?.beginUpdates()
      self.events = newEvents
      if let index = newEvents.firstIndex(where: { event in event.id == id }) {
        agendaViewController?.insertEvent(at: index)
      } else if let index = oldEvents.firstIndex(where: { event in event.id == id }) {
        agendaViewController?.deleteEvent(at: index)
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

  @objc private func didTapSoon() {
    let operation = EventsStartingIn30Minutes(now: now)
    dependencies.persistenceService.performRead(operation) { result in
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }

        switch result {
        case .failure:
          let errorViewController = UIAlertController.makeErrorController()
          self.present(errorViewController, animated: true)
        case let .success(events):
          self.eventsStartingSoon = events
          let soonViewController = self.makeSoonViewController()
          let soonNavigationController = UINavigationController(rootViewController: soonViewController)
          self.present(soonNavigationController, animated: true)
        }
      }
    }
  }

  @objc private func didTapDismiss() {
    soonViewController?.dismiss(animated: true)
  }

  private func didChangeRootViewController(from oldViewController: UIViewController?, to newViewController: UIViewController?) {
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

  private func preselectFirstEvent() {
    if let event = events.first, traitCollection.horizontalSizeClass == .regular {
      let eventViewController = makeEventViewController(for: event)
      agendaViewController?.showDetailViewController(eventViewController, sender: nil)
      agendaViewController?.select(event)
    }
  }
}

extension AgendaController: EventsViewControllerDataSource, EventsViewControllerDelegate {
  func events(in eventsViewController: EventsViewController) -> [Event] {
    switch eventsViewController {
    case agendaViewController:
      return events
    case soonViewController:
      return eventsStartingSoon
    default:
      return []
    }
  }

  func eventsViewController(_ eventsViewController: EventsViewController, captionFor event: Event) -> String? {
    let items: [String?]

    switch eventsViewController {
    case agendaViewController:
      items = [event.formattedStart, event.room, event.track]
    case soonViewController:
      items = [event.formattedStart, event.room]
    default:
      return nil
    }

    return items.compactMap { $0 }.joined(separator: " - ")
  }

  func eventsViewController(_ eventsViewController: EventsViewController, didSelect event: Event) {
    switch eventsViewController {
    case soonViewController:
      let eventViewController = makeSoonEventViewController(for: event)
      eventsViewController.show(eventViewController, sender: nil)
    case agendaViewController where eventViewController?.fos_eventID == event.id && traitCollection.horizontalSizeClass == .regular:
      break
    case agendaViewController:
      let eventViewController = makeEventViewController(for: event)
      eventsViewController.showDetailViewController(eventViewController, sender: nil)
      UIAccessibility.post(notification: .screenChanged, argument: eventViewController.view)
    default:
      break
    }
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
    eventsViewController == agendaViewController && event.isLive(at: now)
  }
}

private extension AgendaController {
  func makeAgendaSplitViewController() -> UISplitViewController {
    let agendaSplitViewController = UISplitViewController()
    agendaSplitViewController.viewControllers = [makeAgendaNavigationController()]
    agendaSplitViewController.preferredPrimaryColumnWidthFraction = 0.4
    #if targetEnvironment(macCatalyst)
    agendaSplitViewController.preferredDisplayMode = .oneBesideSecondary
    #else
    agendaSplitViewController.preferredDisplayMode = .allVisible
    #endif
    agendaSplitViewController.maximumPrimaryColumnWidth = 375
    return agendaSplitViewController
  }

  func makeAgendaNavigationController() -> UINavigationController {
    let agendaViewController = makeAgendaViewController()
    let agendaNavigationController = UINavigationController(rootViewController: agendaViewController)
    agendaNavigationController.navigationBar.prefersLargeTitles = true
    return agendaNavigationController
  }

  func makeAgendaViewController() -> EventsViewController {
    let soonTitle = L10n.Agenda.soon
    let soonAction = #selector(didTapSoon)
    let soonButton = UIBarButtonItem(title: soonTitle, style: .plain, target: self, action: soonAction)
    soonButton.accessibilityIdentifier = "soon"

    let agendaViewController = EventsViewController(style: .grouped)
    agendaViewController.emptyBackgroundMessage = L10n.Agenda.Empty.message
    agendaViewController.emptyBackgroundTitle = L10n.Agenda.Empty.title
    agendaViewController.title = L10n.Agenda.title
    agendaViewController.navigationItem.largeTitleDisplayMode = .always
    agendaViewController.navigationItem.rightBarButtonItem = soonButton
    agendaViewController.favoritesDataSource = self
    agendaViewController.favoritesDelegate = self
    agendaViewController.liveDataSource = self
    agendaViewController.dataSource = self
    agendaViewController.delegate = self
    self.agendaViewController = agendaViewController
    return agendaViewController
  }

  func makeSoonViewController() -> EventsViewController {
    let dismissAction = #selector(didTapDismiss)
    let dismissButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: dismissAction)
    dismissButton.accessibilityIdentifier = "dismiss"

    let soonViewController = EventsViewController(style: .grouped)
    soonViewController.emptyBackgroundMessage = L10n.Soon.Empty.message
    soonViewController.emptyBackgroundTitle = L10n.Soon.Empty.title
    soonViewController.title = L10n.Soon.title
    soonViewController.navigationItem.rightBarButtonItem = dismissButton
    soonViewController.favoritesDataSource = self
    soonViewController.favoritesDelegate = self
    soonViewController.dataSource = self
    soonViewController.delegate = self
    self.soonViewController = soonViewController
    return soonViewController
  }

  func makeEventViewController(for event: Event) -> UIViewController {
    let eventViewController = dependencies.navigationService.makeEventViewController(for: event)
    eventViewController.fos_eventID = event.id
    self.eventViewController = eventViewController
    return eventViewController
  }

  func makeSoonEventViewController(for event: Event) -> UIViewController {
    let eventViewController = dependencies.navigationService.makeEventViewController(for: event)
    eventViewController.fos_eventID = event.id
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

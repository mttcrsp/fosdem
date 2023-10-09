import Dependencies
import UIKit

final class AgendaController: UIViewController {
  @Dependency(\.favoritesClient) var favoritesClient
  @Dependency(\.navigationClient) var navigationClient
  @Dependency(\.persistenceClient) var persistenceClient
  @Dependency(\.soonClient) var soonClient
  @Dependency(\.timeClient) var timeClient

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

  private var isMissingSecondaryViewController: Bool {
    eventViewController == nil
  }

  func popToRootViewController() {
    if traitCollection.horizontalSizeClass == .compact {
      agendaViewController?.navigationController?.popToRootViewController(animated: true)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    reloadFavoriteEvents(animated: false)
    observations = [
      favoritesClient.addObserverForEvents { [weak self] in
        self?.reloadFavoriteEvents(animated: true)
      },
      timeClient.addObserver { [weak self] in
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

  private func reloadFavoriteEvents(animated: Bool) {
    let identifiers = favoritesClient.eventsIdentifiers()

    if identifiers.isEmpty, !(rootViewController is UINavigationController) {
      rootViewController = makeAgendaNavigationController()
    } else if !identifiers.isEmpty, !(rootViewController is UISplitViewController) {
      rootViewController = makeAgendaSplitViewController()
    }

    persistenceClient.eventsByIdentifier(identifiers) { result in
      DispatchQueue.main.async { [weak self] in
        switch result {
        case let .failure(error):
          self?.loadingDidFail(with: error)
        case let .success(events):
          self?.loadingDidSucceed(with: events, animated: animated)
        }
      }
    }
  }

  private func loadingDidFail(with error: Error) {
    didError?(self, error)
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

  @objc private func didTapSoon() {
    soonClient.loadEvents { result in
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

private extension AgendaController {
  func makeAgendaSplitViewController() -> UISplitViewController {
    let agendaSplitViewController = UISplitViewController()
    agendaSplitViewController.viewControllers = [makeAgendaNavigationController()]
    agendaSplitViewController.preferredPrimaryColumnWidthFraction = 0.4
    agendaSplitViewController.preferredDisplayMode = .oneBesideSecondary
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
    agendaViewController.favoriting = favoritesClient.favoriting
    agendaViewController.liveDisplaying = .init { [weak self] event in
      if let self {
        event.isLive(at: self.timeClient.now())
      } else {
        false
      }
    }
    agendaViewController.events = events
    agendaViewController.onEventTap = { [weak self, weak agendaViewController] event in
      if let self, eventViewController?.fos_eventID == event.id, traitCollection.horizontalSizeClass == .regular {
        return
      }

      if let self, let agendaViewController {
        let eventViewController = makeEventViewController(for: event)
        agendaViewController.showDetailViewController(eventViewController, sender: nil)
        UIAccessibility.post(notification: .screenChanged, argument: eventViewController.view)
      }
    }
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
    soonViewController.favoriting = favoritesClient.favoriting
    soonViewController.events = eventsStartingSoon
    soonViewController.onEventTap = { [weak self, weak soonViewController] event in
      if let self, let soonViewController {
        let eventViewController = makeSoonEventViewController(for: event)
        soonViewController.show(eventViewController, sender: nil)
      }
    }
    self.soonViewController = soonViewController
    return soonViewController
  }

  func makeEventViewController(for event: Event) -> UIViewController {
    let eventViewController = navigationClient.makeEventViewController(event)
    eventViewController.fos_eventID = event.id
    self.eventViewController = eventViewController
    return eventViewController
  }

  func makeSoonEventViewController(for event: Event) -> UIViewController {
    let eventViewController = navigationClient.makeEventViewController(event)
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

extension FavoritesClient {
  var favoriting: EventsViewController.Favoriting {
    .init(
      isFavorite: contains,
      onFavoriteTap: { event in addEvent(event.id) },
      onUnfavoriteTap: { event in removeEvent(event.id) }
    )
  }
}

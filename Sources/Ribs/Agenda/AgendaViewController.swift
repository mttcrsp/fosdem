import RIBs
import UIKit

protocol AgendaPresentableListener: AnyObject {
  func didSelectSoon()
  func didSelectSoonEvent(_ event: Event)
  func didDeselectSoonEvent()
  func didSelectAgendaEvent(_ event: Event)
  func toggleFavorite(_ event: Event)
  func canFavoriteEvent(_ event: Event) -> Bool
  func shouldShowLiveIndicator(for event: Event) -> Bool
}

final class AgendaViewController: UIViewController {
  typealias Dependencies = HasFavoritesService & HasPersistenceService & HasTimeService & HasSoonService

  weak var listener: AgendaPresentableListener?

  private var agendaEvents: [Event] = []
  private var soonEvents: [Event] = []

  private weak var agendaViewController: EventsViewController?
  private weak var agendaNavigationController: UINavigationController?
  private weak var soonViewController: EventsViewController?
  private weak var soonNavigationController: UINavigationController?
  private weak var eventViewController: UIViewController?

  private weak var rootViewController: UIViewController? {
    didSet { didChangeRootViewController(from: oldValue, to: rootViewController) }
  }
}

extension AgendaViewController: AgendaPresentable {
  func reloadLiveStatus() {
    agendaViewController?.reloadLiveStatus()
  }

  func showError() {
    let errorViewController = UIAlertController.makeErrorController()
    present(errorViewController, animated: true)
  }

  func showSoonEvents(_ soonEvents: [Event]) {
    self.soonEvents = soonEvents

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

    let soonNavigationController = UINavigationController(rootViewController: soonViewController)
    soonNavigationController.delegate = self
    self.soonNavigationController = soonNavigationController

    present(soonNavigationController, animated: true)
  }

  func showAgendaEvents(_ agendaEvents: [Event], withUpdatedEventIdentifier updatedEventID: Int?) {
    if agendaEvents.isEmpty, !(rootViewController is UINavigationController) {
      rootViewController = makeAgendaNavigationController()
    } else if !agendaEvents.isEmpty, !(rootViewController is UISplitViewController) {
      rootViewController = makeAgendaSplitViewController()
    }

    if let id = updatedEventID {
      let oldEvents = self.agendaEvents
      let newEvents = agendaEvents

      agendaViewController?.performBatchUpdates {
        self.agendaEvents = newEvents
        if let index = newEvents.firstIndex(where: { event in event.id == id }) {
          agendaViewController?.insertEvent(at: index)
        } else if let index = oldEvents.firstIndex(where: { event in event.id == id }) {
          agendaViewController?.deleteEvent(at: index)
        }
      }
    } else {
      self.agendaEvents = agendaEvents
      agendaViewController?.reloadData()
    }

    var didDeleteSelectedEvent = false
    if let selectedEventID = eventViewController?.fos_eventID, !agendaEvents.contains(where: { event in event.id == selectedEventID }) {
      didDeleteSelectedEvent = true
    }

    if didDeleteSelectedEvent || isMissingSecondaryViewController {
      showFirstEvent()
    }
  }
}

extension AgendaViewController: AgendaViewControllable {
  func showAgendaEvent(_ event: Event, with viewControllable: ViewControllable) {
    let eventViewController = viewControllable.uiviewController
    eventViewController.fos_eventID = event.id
    self.eventViewController = eventViewController
    agendaViewController?.showDetailViewController(eventViewController, sender: nil)
    UIAccessibility.post(notification: .screenChanged, argument: eventViewController.view)
  }

  func showSoonEvent(_ event: Event, with viewControllable: ViewControllable) {
    let eventViewController = viewControllable.uiviewController
    eventViewController.fos_eventID = event.id
    soonViewController?.show(eventViewController, sender: nil)
    soonViewController?.select(event)
  }
}

extension AgendaViewController {
  private var isMissingSecondaryViewController: Bool {
    eventViewController == nil
  }

  func popToRootViewController() {
    if traitCollection.horizontalSizeClass == .compact {
      agendaViewController?.navigationController?.popToRootViewController(animated: true)
    }
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

    if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass, isMissingSecondaryViewController {
      showFirstEvent()
    }
  }
}

extension AgendaViewController: EventsViewControllerDataSource {
  func events(in eventsViewController: EventsViewController) -> [Event] {
    switch eventsViewController {
    case agendaViewController:
      return agendaEvents
    case soonViewController:
      return soonEvents
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
}

extension AgendaViewController: EventsViewControllerDelegate {
  func eventsViewController(_ eventsViewController: EventsViewController, didSelect event: Event) {
    switch eventsViewController {
    case soonViewController:
      listener?.didSelectSoonEvent(event)
    case agendaViewController where eventViewController?.fos_eventID == event.id && traitCollection.horizontalSizeClass == .regular:
      break
    case agendaViewController:
      listener?.didSelectAgendaEvent(event)
    default:
      break
    }
  }
}

extension AgendaViewController: EventsViewControllerFavoritesDataSource {
  func eventsViewController(_: EventsViewController, canFavorite event: Event) -> Bool {
    listener?.canFavoriteEvent(event) ?? false
  }
}

extension AgendaViewController: EventsViewControllerFavoritesDelegate {
  func eventsViewController(_: EventsViewController, didToggleFavorite event: Event) {
    listener?.toggleFavorite(event)
  }
}

extension AgendaViewController: EventsViewControllerLiveDataSource {
  func eventsViewController(_: EventsViewController, shouldShowLiveIndicatorFor event: Event) -> Bool {
    if eventViewController == agendaViewController {
      return listener?.shouldShowLiveIndicator(for: event) ?? false
    } else {
      return false
    }
  }
}

extension AgendaViewController: UINavigationControllerDelegate {
  func navigationController(_ navigationController: UINavigationController, didShow _: UIViewController, animated _: Bool) {
    if navigationController.viewControllers.count == 1, navigationController == soonNavigationController {
      listener?.didDeselectSoonEvent()
    }
  }
}

private extension AgendaViewController {
  @objc func didTapSoon() {
    listener?.didSelectSoon()
  }

  @objc func didTapDismiss() {
    soonViewController?.dismiss(animated: true)
  }

  func showFirstEvent() {
    if let event = agendaEvents.first, traitCollection.horizontalSizeClass == .regular {
      listener?.didSelectAgendaEvent(event)
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

  func makeAgendaSplitViewController() -> UISplitViewController {
    let agendaSplitViewController = UISplitViewController()
    agendaSplitViewController.viewControllers = [makeAgendaNavigationController()]
    agendaSplitViewController.preferredPrimaryColumnWidthFraction = 0.4
    agendaSplitViewController.preferredDisplayMode = .allVisible
    agendaSplitViewController.maximumPrimaryColumnWidth = 375
    return agendaSplitViewController
  }

  func makeAgendaNavigationController() -> UINavigationController {
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

    let agendaNavigationController = UINavigationController(rootViewController: agendaViewController)
    agendaNavigationController.navigationBar.prefersLargeTitles = true
    agendaNavigationController.delegate = self
    self.agendaNavigationController = agendaNavigationController

    return agendaNavigationController
  }
}

private extension UIViewController {
  private static var eventIDKey = 0

  var fos_eventID: Int? {
    get { objc_getAssociatedObject(self, &UIViewController.eventIDKey) as? Int }
    set { objc_setAssociatedObject(self, &UIViewController.eventIDKey, newValue as Int?, .OBJC_ASSOCIATION_COPY_NONATOMIC) }
  }
}

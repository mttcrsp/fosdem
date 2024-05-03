import Combine
import UIKit

final class AgendaViewController: UIViewController {
  typealias Dependencies = HasNavigationService

  var didError: ((AgendaViewController, Error) -> Void)?

  private weak var agendaViewController: EventsViewController?
  private weak var soonViewController: EventsViewController?
  private weak var eventViewController: UIViewController?

  private weak var rootViewController: UIViewController? {
    didSet { didChangeRootViewController(from: oldValue, to: rootViewController) }
  }

  private var cancellables: [AnyCancellable] = []
  private let dependencies: Dependencies
  private let viewModel: AgendaViewModel

  init(dependencies: Dependencies, viewModel: AgendaViewModel) {
    self.dependencies = dependencies
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    viewModel.$events
      .scan(([], [])) { ($0.1, $1) }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] previousEvents, events in
        guard let self else { return }

        if events.isEmpty, !(rootViewController is UINavigationController) {
          rootViewController = makeAgendaNavigationController()
        } else if !events.isEmpty, !(rootViewController is UISplitViewController) {
          let agendaSplitViewController = UISplitViewController()
          agendaSplitViewController.viewControllers = [makeAgendaNavigationController()]
          agendaSplitViewController.preferredPrimaryColumnWidthFraction = 0.4
          agendaSplitViewController.preferredDisplayMode = .oneBesideSecondary
          agendaSplitViewController.maximumPrimaryColumnWidth = 375
          rootViewController = agendaSplitViewController
        }

        if let agendaViewController {
          if agendaViewController.view.window == nil {
            agendaViewController.reloadData()
          } else {
            agendaViewController.beginUpdates()
            for difference in events.difference(from: previousEvents) {
              switch difference {
              case let .insert(index, _, _): agendaViewController.insertEvent(at: index)
              case let .remove(index, _, _): agendaViewController.deleteEvent(at: index)
              }
            }
            agendaViewController.endUpdates()
          }
        }

        var didDeleteSelectedEvent = false
        if let selectedEventID = eventViewController?.fos_eventID, !events.contains(where: { event in event.id == selectedEventID }) {
          didDeleteSelectedEvent = true
        }
        if didDeleteSelectedEvent || isMissingSecondaryViewController {
          preselectFirstEvent()
        }
      }
      .store(in: &cancellables)

    viewModel.$liveEventsIDs
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.agendaViewController?.reloadLiveStatus()
      }
      .store(in: &cancellables)

    viewModel.didFail
      .receive(on: DispatchQueue.main)
      .sink { [weak self] error in
        guard let self else { return }
        didError?(self, error)
      }
      .store(in: &cancellables)

    viewModel.didLoad()
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass, isMissingSecondaryViewController {
      preselectFirstEvent()
    }
  }
}

extension AgendaViewController: EventsViewControllerDataSource, EventsViewControllerDelegate {
  func events(in _: EventsViewController) -> [Event] {
    viewModel.events
  }

  func eventsViewController(_: EventsViewController, captionFor event: Event) -> String? {
    [event.formattedStart, event.room, event.formattedTrack].compactMap { $0 }.joined(separator: " - ")
  }

  func eventsViewController(_ eventsViewController: EventsViewController, didSelect event: Event) {
    if eventViewController?.fos_eventID == event.id, traitCollection.horizontalSizeClass == .regular {} else {
      let eventViewController = makeEventViewController(for: event)
      let navigationController = UINavigationController(rootViewController: eventViewController)
      eventsViewController.showDetailViewController(navigationController, sender: nil)
      UIAccessibility.post(notification: .screenChanged, argument: eventViewController.view)
    }
  }
}

extension AgendaViewController: EventsViewControllerFavoritesDataSource, EventsViewControllerFavoritesDelegate {
  func eventsViewController(_: EventsViewController, canFavorite event: Event) -> Bool {
    viewModel.canFavorite(event)
  }

  func eventsViewController(_: EventsViewController, didFavorite event: Event) {
    viewModel.didFavorite(event)
  }

  func eventsViewController(_: EventsViewController, didUnfavorite event: Event) {
    viewModel.didUnfavorite(event)
  }
}

extension AgendaViewController: EventsViewControllerLiveDataSource {
  func eventsViewController(_: EventsViewController, shouldShowLiveIndicatorFor event: Event) -> Bool {
    viewModel.liveEventsIDs.contains(event.id)
  }
}

extension AgendaViewController {
  func popToRootViewController() {
    if traitCollection.horizontalSizeClass == .compact {
      agendaViewController?.navigationController?.popToRootViewController(animated: true)
    }
  }
}

private extension AgendaViewController {
  var isMissingSecondaryViewController: Bool {
    eventViewController == nil
  }

  func preselectFirstEvent() {
    if let event = viewModel.events.first, traitCollection.horizontalSizeClass == .regular {
      let eventViewController = makeEventViewController(for: event)
      let navigationController = UINavigationController(rootViewController: eventViewController)
      agendaViewController?.showDetailViewController(navigationController, sender: nil)
      agendaViewController?.select(event)
    }
  }

  func didChangeRootViewController(from oldViewController: UIViewController?, to newViewController: UIViewController?) {
    if let viewController = oldViewController {
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

  @objc func didTapSoon() {
    let soonViewController = dependencies.navigationService.makeSoonViewController()
    present(soonViewController, animated: true)
  }
}

private extension AgendaViewController {
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
    return agendaNavigationController
  }

  func makeEventViewController(for event: Event) -> UIViewController {
    let eventOptions: EventOptions = [.enableFavoriting, .enableTrackSelection]
    let eventViewController = dependencies.navigationService.makeEventViewController(for: event, options: eventOptions)
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

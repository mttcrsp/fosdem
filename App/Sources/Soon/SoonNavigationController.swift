import Combine
import UIKit

final class SoonNavigationController: UINavigationController {
  typealias Dependencies = HasNavigationService

  private var cancellables: [AnyCancellable] = []
  private weak var eventsViewController: EventsViewController?
  private let dependencies: Dependencies
  private let viewModel: SoonViewModel

  init(dependencies: Dependencies, viewModel: SoonViewModel) {
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

    let dismissAction = #selector(didTapDismiss)
    let dismissButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: dismissAction)
    dismissButton.accessibilityIdentifier = "dismiss"

    let eventsViewController = EventsViewController(style: .grouped)
    eventsViewController.title = L10n.Soon.title
    eventsViewController.emptyBackgroundMessage = L10n.Soon.Empty.message
    eventsViewController.emptyBackgroundTitle = L10n.Soon.Empty.title
    eventsViewController.favoritesDataSource = self
    eventsViewController.favoritesDelegate = self
    eventsViewController.dataSource = self
    eventsViewController.delegate = self
    eventsViewController.navigationItem.rightBarButtonItem = dismissButton
    self.eventsViewController = eventsViewController
    viewControllers = [eventsViewController]

    viewModel.$events
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.eventsViewController?.reloadData()
      }
      .store(in: &cancellables)

    viewModel.didLoad()
  }
}

extension SoonNavigationController: EventsViewControllerDataSource, EventsViewControllerDelegate {
  func events(in _: EventsViewController) -> [Event] {
    viewModel.events
  }

  func eventsViewController(_: EventsViewController, captionFor event: Event) -> String? {
    [event.formattedStart, event.room].compactMap { $0 }.joined(separator: " - ")
  }

  func eventsViewController(_ eventsViewController: EventsViewController, didSelect event: Event) {
    let eventOptions: EventOptions = [.enableFavoriting, .enableTrackSelection]
    let eventViewController = dependencies.navigationService.makeEventViewController(for: event, options: eventOptions)
    eventsViewController.show(eventViewController, sender: nil)
  }
}

extension SoonNavigationController: EventsViewControllerFavoritesDataSource, EventsViewControllerFavoritesDelegate {
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

private extension SoonNavigationController {
  @objc func didTapDismiss() {
    eventsViewController?.dismiss(animated: true)
  }
}

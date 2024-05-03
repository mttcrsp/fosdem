import Combine
import UIKit

final class TrackViewController: EventsViewController {
  typealias Dependencies = HasNavigationService

  var didError: ((UIViewController, Error) -> Void)?
  private var cancellables: [AnyCancellable] = []
  private var favoriteButton: UIBarButtonItem?
  private let dependencies: Dependencies
  private let viewModel: TrackViewModel

  init(style: UITableView.Style, dependencies: Dependencies, viewModel: TrackViewModel) {
    self.dependencies = dependencies
    self.viewModel = viewModel
    super.init(style: style)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    dataSource = self
    delegate = self
    favoritesDataSource = self
    favoritesDelegate = self

    let favoriteAction = #selector(didToggleFavorite)
    let favoriteButton = UIBarButtonItem(title: nil, style: .plain, target: self, action: favoriteAction)
    self.favoriteButton = favoriteButton
    navigationItem.rightBarButtonItem = favoriteButton

    viewModel.$isTrackFavorite
      .receive(on: DispatchQueue.main)
      .sink { [weak self] isFavorite in
        self?.favoriteButton?.accessibilityIdentifier = isFavorite ? "unfavorite" : "favorite"
        self?.favoriteButton?.title = isFavorite ? L10n.unfavorite : L10n.favorite
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
}

extension TrackViewController: EventsViewControllerDataSource, EventsViewControllerDelegate {
  func events(in _: EventsViewController) -> [Event] {
    viewModel.events
  }

  func eventsViewController(_: EventsViewController, captionFor event: Event) -> String? {
    viewModel.captions[event]
  }

  func eventsViewController(_: EventsViewController, didSelect event: Event) {
    let eventOptions: EventOptions = [.enableFavoriting]
    let eventViewController = dependencies.navigationService.makeEventViewController(for: event, options: eventOptions)
    show(eventViewController, sender: nil)
  }
}

extension TrackViewController: EventsViewControllerFavoritesDataSource, EventsViewControllerFavoritesDelegate {
  func eventsViewController(_: EventsViewController, canFavorite event: Event) -> Bool {
    viewModel.canFavorite(event)
  }

  func eventsViewController(_: EventsViewController, didFavorite event: Event) {
    viewModel.didFavorite(event)
  }

  func eventsViewController(_: EventsViewController, didUnfavorite event: Event) {
    viewModel.didUnfavorite(event)
  }

  @objc private func didToggleFavorite() {
    viewModel.didToggleFavorite()
  }
}

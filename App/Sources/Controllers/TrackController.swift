import UIKit

final class TrackController: EventsViewController {
  typealias Dependencies = HasFavoritesService & HasNavigationService & HasPersistenceService & HasDateFormattingService

  var didError: ((UIViewController, Error) -> Void)?
  private var favoriteButton: UIBarButtonItem?
  private var captions: [Event: String] = [:]
  private var observers: [NSObjectProtocol] = []
  private let dependencies: Dependencies
  private let track: Track

  init(track: Track, style: UITableView.Style, dependencies: Dependencies) {
    self.dependencies = dependencies
    self.track = track
    super.init(style: style)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func load(_ completion: @escaping (Error?) -> Void) {
    dependencies.persistenceService.performRead(GetEventsByTrack(track: track.name)) { result in
      DispatchQueue.main.async { [weak self] in
        guard let self else { return }

        switch result {
        case let .failure(error):
          completion(error)
        case let .success(events):
          captions = makeCaptions(for: events)
          setEvents(events)
          completion(nil)
        }
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    delegate = self
    favoritesDataSource = self
    favoritesDelegate = self

    let favoriteAction = #selector(didToggleFavorite)
    let favoriteButton = UIBarButtonItem(title: nil, style: .plain, target: self, action: favoriteAction)
    self.favoriteButton = favoriteButton
    navigationItem.rightBarButtonItem = favoriteButton

    reloadFavoriteButton()
    observers = [
      dependencies.favoritesService.addObserverForTracks { [weak self] in
        self?.reloadFavoriteButton()
      },
      dependencies.dateFormattingService.addObserverForFormattingTimeZoneChanges { [weak self] in
        guard let self else { return }
        captions = makeCaptions(for: events)
        reloadData()
      }
    ]
  }

  private func reloadFavoriteButton() {
    let isFavorite = dependencies.favoritesService.contains(track)
    favoriteButton?.accessibilityIdentifier = isFavorite ? "unfavorite" : "favorite"
    favoriteButton?.title = isFavorite ? L10n.unfavorite : L10n.favorite
  }
}

extension TrackController: EventsViewControllerDelegate {
  func eventsViewController(_: EventsViewController, captionFor event: Event) -> String? {
    captions[event]
  }

  func eventsViewController(_: EventsViewController, didSelect event: Event) {
    let eventViewController = dependencies.navigationService.makeEventViewController(for: event)
    eventViewController.allowsTrackSelection = false
    show(eventViewController, sender: nil)
  }
}

extension TrackController: EventsViewControllerFavoritesDataSource, EventsViewControllerFavoritesDelegate {
  func eventsViewController(_: EventsViewController, canFavorite event: Event) -> Bool {
    !dependencies.favoritesService.contains(event)
  }

  func eventsViewController(_: EventsViewController, didFavorite event: Event) {
    dependencies.favoritesService.addEvent(withIdentifier: event.id)
  }

  func eventsViewController(_: EventsViewController, didUnfavorite event: Event) {
    dependencies.favoritesService.removeEvent(withIdentifier: event.id)
  }

  @objc private func didToggleFavorite() {
    if dependencies.favoritesService.contains(track) {
      dependencies.favoritesService.removeTrack(withIdentifier: track.name)
    } else {
      dependencies.favoritesService.addTrack(withIdentifier: track.name)
    }
  }
}

private extension TrackController {
  func makeCaptions(for events: [Event]) -> [Event: String] {
    let components: [(event: Event, start: String, weekday: String)] =
      events.map { event in
        (event,
         dependencies.dateFormattingService.time(from: event.date),
         dependencies.dateFormattingService.weekday(from: event.date))
      }

    var captions: [Event: String] = [:]
    for (i, component) in components.enumerated() {
      captions[component.event] =
        if i == 0 || components[i].weekday != components[i - 1].weekday {
          L10n.Search.Event.start(component.start, component.weekday)
        } else {
          component.start
        }
    }

    return captions
  }
}

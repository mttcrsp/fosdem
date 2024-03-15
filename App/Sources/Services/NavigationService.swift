import AVKit
import SafariServices

final class NavigationService {
  typealias ErrorHandler = (UIViewController, Error) -> Void
  typealias LoadingHandler = (Result<UIViewController, Error>) -> Void

  private unowned var services: Services!

  init(services: Services) {
    self.services = services
  }
}

extension NavigationService {
  func makeSearchViewController() -> UIViewController {
    let searchController = SearchController(dependencies: services)
    searchController.tabBarItem.accessibilityIdentifier = "search"
    searchController.tabBarItem.image = UIImage(systemName: "magnifyingglass")
    searchController.title = L10n.Search.title
    searchController.preferredDisplayMode = .oneBesideSecondary
    searchController.preferredPrimaryColumnWidthFraction = 0.4
    searchController.maximumPrimaryColumnWidth = 375
    return searchController
  }

  func makeAgendaViewController(didError: @escaping ErrorHandler) -> UIViewController {
    let agendaController = AgendaController(dependencies: services)
    agendaController.tabBarItem.accessibilityIdentifier = "agenda"
    agendaController.tabBarItem.image = UIImage(systemName: "calendar")
    agendaController.title = L10n.Agenda.title
    agendaController.didError = didError
    return agendaController
  }

  func makeMapViewController(didError: @escaping ErrorHandler) -> UIViewController {
    let mapController = MapController(dependencies: services)
    mapController.tabBarItem.accessibilityIdentifier = "map"
    mapController.tabBarItem.image = UIImage(systemName: "map")
    mapController.title = L10n.Map.title
    mapController.didError = didError
    return mapController
  }

  func makeMoreViewController() -> UIViewController {
    let moreController = MoreController(dependencies: services)
    moreController.tabBarItem.accessibilityIdentifier = "more"
    moreController.tabBarItem.image = UIImage(systemName: "ellipsis.circle")
    moreController.title = L10n.More.title
    moreController.preferredDisplayMode = .oneBesideSecondary
    moreController.preferredPrimaryColumnWidthFraction = 0.4
    moreController.maximumPrimaryColumnWidth = 375
    return moreController
  }
}

extension NavigationService {
  func loadTrackViewController(for track: Track, style: UITableView.Style, completion: @escaping LoadingHandler) {
    let trackController = TrackController(track: track, style: style, dependencies: services)
    trackController.load { error in
      if let error {
        completion(.failure(error))
      } else {
        completion(.success(trackController))
      }
    }
  }
}

extension NavigationService {
  func makeEventViewController(for event: Event) -> UIViewController {
    EventController(event: event, dependencies: services)
  }

  func makePastEventViewController(for event: Event) -> UIViewController {
    let eventController = EventController(event: event, dependencies: services)
    eventController.showsFavoriteButton = false
    return eventController
  }
}

extension NavigationService {
  func makeVideosViewController(didError: @escaping ErrorHandler) -> UIViewController {
    let videosController = VideosController(dependencies: services)
    videosController.didError = didError
    return videosController
  }
}

extension NavigationService {
  func makeYearsViewController(withStyle style: UITableView.Style, didError: @escaping ErrorHandler) -> UIViewController {
    let yearsController = YearsController(style: style, dependencies: services)
    yearsController.didError = didError
    return yearsController
  }

  func makeYearsViewController(forYear year: Int, with persistenceService: PersistenceServiceProtocol, didError: @escaping ErrorHandler) -> UIViewController {
    let yearController = YearController(persistenceService: persistenceService, dependencies: services)
    yearController.navigationItem.largeTitleDisplayMode = .never
    yearController.title = year.description
    yearController.didError = didError
    return yearController
  }
}

extension NavigationService {
  func loadInfoViewController(withTitle title: String, info: Info, completion: @escaping LoadingHandler) {
    let infoController = InfoController(info: info, dependencies: services)
    infoController.accessibilityIdentifier = info.accessibilityIdentifier
    infoController.title = title
    infoController.load { error in
      if let error {
        completion(.failure(error))
      } else {
        completion(.success(infoController))
      }
    }
  }
}

extension NavigationService {
  typealias PlayerViewController = AVPlayerViewControllerProtocol & UIViewController

  func makePlayerViewController() -> PlayerViewController {
    AVPlayerViewController()
  }

  func makeSafariViewController(with url: URL) -> UIViewController {
    SFSafariViewController(url: url)
  }
}

extension NavigationService {
  func makeTransportationViewController() -> UIViewController {
    TransportationController(dependencies: services)
  }
}

/// @mockable
protocol NavigationServiceProtocol {
  func makeSearchViewController() -> UIViewController
  func makeAgendaViewController(didError: @escaping NavigationService.ErrorHandler) -> UIViewController
  func makeMapViewController(didError: @escaping NavigationService.ErrorHandler) -> UIViewController
  func makeMoreViewController() -> UIViewController

  func loadTrackViewController(for track: Track, style: UITableView.Style, completion: @escaping NavigationService.LoadingHandler)

  func makeEventViewController(for event: Event) -> UIViewController
  func makePastEventViewController(for event: Event) -> UIViewController

  func makeTransportationViewController() -> UIViewController
  func makeVideosViewController(didError: @escaping NavigationService.ErrorHandler) -> UIViewController
  func loadInfoViewController(withTitle title: String, info: Info, completion: @escaping NavigationService.LoadingHandler)

  func makeYearsViewController(withStyle style: UITableView.Style, didError: @escaping NavigationService.ErrorHandler) -> UIViewController
  func makeYearsViewController(forYear year: Int, with persistenceService: PersistenceServiceProtocol, didError: @escaping NavigationService.ErrorHandler) -> UIViewController

  func makePlayerViewController() -> NavigationService.PlayerViewController
  func makeSafariViewController(with url: URL) -> UIViewController
}

extension NavigationService: NavigationServiceProtocol {}

protocol AVPlayerViewControllerProtocol: AnyObject {
  var delegate: AVPlayerViewControllerDelegate? { get set }
  var exitsFullScreenWhenPlaybackEnds: Bool { get set }
  var player: AVPlayer? { get set }
}

extension AVPlayerViewController: AVPlayerViewControllerProtocol {}

protocol HasNavigationService {
  var navigationService: NavigationServiceProtocol { get }
}

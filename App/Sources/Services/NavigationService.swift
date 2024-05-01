import AVKit
import SafariServices

final class NavigationService {
  private unowned var services: Services!

  init(services: Services) {
    self.services = services
  }
}

extension NavigationService {
  func makeAgendaViewController() -> AgendaController {
    AgendaController(dependencies: services)
  }

  func makeEventViewController(for event: Event) -> EventController {
    EventController(event: event, dependencies: services)
  }

  func makeInfoViewController(for info: Info) -> InfoController {
    InfoController(info: info, dependencies: services)
  }

  func makeMapViewController() -> MapController {
    MapController(dependencies: services)
  }

  func makeMoreViewController() -> MoreController {
    MoreController(dependencies: services)
  }

  func makePlayerViewController() -> AVPlayerViewControllerProtocol {
    AVPlayerViewController()
  }

  func makeSafariViewController(with url: URL) -> SFSafariViewController {
    SFSafariViewController(url: url)
  }

  func makeSearchViewController() -> SearchController {
    SearchController(dependencies: services)
  }

  func makeTrackViewController(for track: Track, style: UITableView.Style) -> TrackController {
    TrackController(track: track, style: style, dependencies: services)
  }

  func makeTransportationViewController() -> TransportationNavigationController {
    let viewModel = TransportationViewModel(dependencies: services)
    return TransportationNavigationController(viewModel: viewModel)
  }

  func makeVideosViewController() -> VideosController {
    VideosController(dependencies: services)
  }

  func makeYearsViewController(withStyle style: UITableView.Style) -> YearsController {
    YearsController(style: style, dependencies: services)
  }

  func makeYearViewController(for persistenceService: PersistenceServiceProtocol) -> YearController {
    YearController(persistenceService: persistenceService, dependencies: services)
  }
}

/// @mockable
protocol NavigationServiceProtocol {
  func makeAgendaViewController() -> AgendaController
  func makeEventViewController(for event: Event) -> EventController
  func makeInfoViewController(for info: Info) -> InfoController
  func makeMapViewController() -> MapController
  func makeMoreViewController() -> MoreController
  func makePlayerViewController() -> AVPlayerViewControllerProtocol
  func makeSafariViewController(with url: URL) -> SFSafariViewController
  func makeSearchViewController() -> SearchController
  func makeTrackViewController(for track: Track, style: UITableView.Style) -> TrackController
  func makeTransportationViewController() -> TransportationNavigationController
  func makeVideosViewController() -> VideosController
  func makeYearsViewController(withStyle style: UITableView.Style) -> YearsController
  func makeYearViewController(for persistenceService: PersistenceServiceProtocol) -> YearController
}

extension NavigationService: NavigationServiceProtocol {}

protocol HasNavigationService {
  var navigationService: NavigationServiceProtocol { get }
}

protocol AVPlayerViewControllerProtocol: UIViewController {
  var delegate: AVPlayerViewControllerDelegate? { get set }
  var exitsFullScreenWhenPlaybackEnds: Bool { get set }
  var player: AVPlayer? { get set }
}

extension AVPlayerViewController: AVPlayerViewControllerProtocol {}

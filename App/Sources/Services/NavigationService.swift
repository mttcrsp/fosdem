import AVKit
import SafariServices

final class NavigationService {
  private unowned var services: Services!

  init(services: Services) {
    self.services = services
  }
}

extension NavigationService {
  func makeAgendaViewController() -> AgendaViewController {
    let viewModel = AgendaViewModel(dependencies: services)
    return AgendaViewController(dependencies: services, viewModel: viewModel)
  }

  func makeEventViewController(for event: Event, options: EventOptions) -> EventViewController {
    let viewModel = EventViewModel(event: event, options: options, dependencies: services)
    return EventViewController(dependencies: services, viewModel: viewModel)
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

  func makeSoonViewController() -> SoonNavigationController {
    let viewModel = SoonViewModel(dependencies: services)
    return SoonNavigationController(dependencies: services, viewModel: viewModel)
  }

  func makeTrackViewController(for track: Track, style: UITableView.Style) -> TrackController {
    TrackController(track: track, style: style, dependencies: services)
  }

  func makeTransportationViewController() -> TransportationNavigationController {
    let viewModel = TransportationViewModel(dependencies: services)
    return TransportationNavigationController(viewModel: viewModel)
  }

  func makeVideosViewController() -> VideosViewController {
    let viewModel = VideosViewModel(dependencies: services)
    return VideosViewController(dependencies: services, viewModel: viewModel)
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
  func makeAgendaViewController() -> AgendaViewController
  func makeEventViewController(for event: Event, options: EventOptions) -> EventViewController
  func makeInfoViewController(for info: Info) -> InfoController
  func makeMapViewController() -> MapController
  func makeMoreViewController() -> MoreController
  func makePlayerViewController() -> AVPlayerViewControllerProtocol
  func makeSafariViewController(with url: URL) -> SFSafariViewController
  func makeSearchViewController() -> SearchController
  func makeSoonViewController() -> SoonNavigationController
  func makeTrackViewController(for track: Track, style: UITableView.Style) -> TrackController
  func makeTransportationViewController() -> TransportationNavigationController
  func makeVideosViewController() -> VideosViewController
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

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

  func makeMapViewController() -> MapMainViewController {
    let viewModel = MapViewModel(dependencies: services)
    return MapMainViewController(viewModel: viewModel)
  }

  func makeMoreViewController() -> MoreMainViewController {
    let viewModel = MoreViewModel(dependencies: services)
    return MoreMainViewController(dependencies: services, viewModel: viewModel)
  }

  func makeSearchViewController() -> SearchController {
    SearchController(dependencies: services)
  }

  func makeSoonViewController() -> SoonNavigationController {
    let viewModel = SoonViewModel(dependencies: services)
    return SoonNavigationController(dependencies: services, viewModel: viewModel)
  }

  func makeTrackViewController(for track: Track, style: UITableView.Style) -> TrackViewController {
    let viewModel = TrackViewModel(track: track, dependencies: services)
    return TrackViewController(style: style, dependencies: services, viewModel: viewModel)
  }

  func makeTransportationViewController() -> TransportationNavigationController {
    let viewModel = TransportationViewModel(dependencies: services)
    return TransportationNavigationController(viewModel: viewModel)
  }

  func makeVideosViewController() -> VideosViewController {
    let viewModel = VideosViewModel(dependencies: services)
    return VideosViewController(dependencies: services, viewModel: viewModel)
  }

  func makeYearsViewController(withStyle style: UITableView.Style) -> YearsViewController {
    let viewModel = YearsViewModel(dependencies: services)
    return YearsViewController(style: style, dependencies: services, viewModel: viewModel)
  }

  func makeYearViewController(for persistenceService: PersistenceServiceProtocol) -> YearViewController {
    let searchViewModel = SearchResultViewModel(persistenceService: persistenceService)
    let viewModel = YearViewModel(persistenceService: persistenceService)
    return YearViewController(dependencies: services, viewModel: viewModel, searchViewModel: searchViewModel)
  }

  #if DEBUG
  func makeDateViewController() -> DateViewController {
    let viewModel = DateViewModel(dependencies: services)
    return DateViewController(viewModel: viewModel)
  }
  #endif
}

/// @mockable
protocol NavigationServiceProtocol {
  func makeAgendaViewController() -> AgendaViewController
  func makeEventViewController(for event: Event, options: EventOptions) -> EventViewController
  func makeMapViewController() -> MapMainViewController
  func makeMoreViewController() -> MoreMainViewController
  func makeSearchViewController() -> SearchController
  func makeSoonViewController() -> SoonNavigationController
  func makeTrackViewController(for track: Track, style: UITableView.Style) -> TrackViewController
  func makeTransportationViewController() -> TransportationNavigationController
  func makeVideosViewController() -> VideosViewController
  func makeYearsViewController(withStyle style: UITableView.Style) -> YearsViewController
  func makeYearViewController(for persistenceService: PersistenceServiceProtocol) -> YearViewController

  #if DEBUG
  func makeDateViewController() -> DateViewController
  #endif
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

import AVKit
import SafariServices

struct NavigationService {
  typealias ErrorHandler = (UIViewController, Error) -> Void

  typealias PlayerViewController = UIViewController & AVPlayerViewControllerProtocol

  var makeSearchViewController: () -> UIViewController
  var makeAgendaViewController: (@escaping NavigationService.ErrorHandler) -> UIViewController
  var makeMapViewController: (@escaping NavigationService.ErrorHandler) -> UIViewController
  var makeMoreViewController: () -> UIViewController

  var makeEventViewController: (Event) -> UIViewController
  var makePastEventViewController: (Event) -> UIViewController

  var makeTransportationViewController: () -> UIViewController
  var makeVideosViewController: (@escaping NavigationService.ErrorHandler) -> UIViewController
  var makeInfoViewController: (String, Info, @escaping NavigationService.ErrorHandler) -> UIViewController

  var makeYearsViewController: (UITableView.Style, @escaping NavigationService.ErrorHandler) -> UIViewController
  var makeYearViewController: (Int, PersistenceServiceProtocol, @escaping NavigationService.ErrorHandler) -> UIViewController

  var makePlayerViewController: () -> NavigationService.PlayerViewController
  var makeSafariViewController: (URL) -> UIViewController
}

extension NavigationService {
  init(services: Services) {
    makeSearchViewController = {
      let searchController = SearchController(dependencies: services)
      searchController.tabBarItem.accessibilityIdentifier = "search"
      searchController.tabBarItem.image = UIImage(systemName: "magnifyingglass")
      searchController.title = L10n.Search.title
      searchController.preferredDisplayMode = .oneBesideSecondary
      searchController.preferredPrimaryColumnWidthFraction = 0.4
      searchController.maximumPrimaryColumnWidth = 375
      return searchController
    }

    makeAgendaViewController = { didError in
      let agendaController = AgendaController(dependencies: services)
      agendaController.tabBarItem.accessibilityIdentifier = "agenda"
      agendaController.tabBarItem.image = UIImage(systemName: "calendar")
      agendaController.title = L10n.Agenda.title
      agendaController.didError = didError
      return agendaController
    }

    makeMapViewController = { didError in
      let mapController = MapController(dependencies: services)
      mapController.tabBarItem.accessibilityIdentifier = "map"
      mapController.tabBarItem.image = UIImage(systemName: "map")
      mapController.title = L10n.Map.title
      mapController.didError = didError
      return mapController
    }

    makeMoreViewController = {
      let moreController = MoreController(dependencies: services)
      moreController.tabBarItem.accessibilityIdentifier = "more"
      moreController.tabBarItem.image = UIImage(systemName: "ellipsis.circle")
      moreController.title = L10n.More.title
      moreController.preferredDisplayMode = .oneBesideSecondary
      moreController.preferredPrimaryColumnWidthFraction = 0.4
      moreController.maximumPrimaryColumnWidth = 375
      return moreController
    }

    makeEventViewController = { event in
      EventController(event: event, dependencies: services)
    }

    makePastEventViewController = { event in
      let eventController = EventController(event: event, dependencies: services)
      eventController.showsFavoriteButton = false
      return eventController
    }

    makeVideosViewController = { didError in
      let videosController = VideosController(dependencies: services)
      videosController.didError = didError
      return videosController
    }

    makeYearsViewController = { style, didError in
      let yearsController = YearsController(style: style, dependencies: services)
      yearsController.didError = didError
      return yearsController
    }

    makeYearViewController = { year, persistenceService, didError in
      let yearController = YearController(persistenceService: persistenceService, dependencies: services)
      yearController.navigationItem.largeTitleDisplayMode = .never
      yearController.title = year.description
      yearController.didError = didError
      return yearController
    }

    makeInfoViewController = { title, info, didError in
      let infoController = InfoController(info: info, dependencies: services)
      infoController.accessibilityIdentifier = info.accessibilityIdentifier
      infoController.didError = didError
      infoController.title = title
      return infoController
    }

    makePlayerViewController = {
      AVPlayerViewController()
    }

    makeSafariViewController = { url in
      SFSafariViewController(url: url)
    }

    makeTransportationViewController = {
      TransportationController(dependencies: services)
    }
  }
}

/// @mockable
protocol NavigationServiceProtocol {
  var makeSearchViewController: () -> UIViewController { get }
  var makeAgendaViewController: (@escaping NavigationService.ErrorHandler) -> UIViewController { get }
  var makeMapViewController: (@escaping NavigationService.ErrorHandler) -> UIViewController { get }
  var makeMoreViewController: () -> UIViewController { get }

  var makeEventViewController: (Event) -> UIViewController { get }
  var makePastEventViewController: (Event) -> UIViewController { get }

  var makeTransportationViewController: () -> UIViewController { get }
  var makeVideosViewController: (@escaping NavigationService.ErrorHandler) -> UIViewController { get }
  var makeInfoViewController: (String, Info, @escaping NavigationService.ErrorHandler) -> UIViewController { get }

  var makeYearsViewController: (UITableView.Style, @escaping NavigationService.ErrorHandler) -> UIViewController { get }
  var makeYearViewController: (Int, PersistenceServiceProtocol, @escaping NavigationService.ErrorHandler) -> UIViewController { get }

  var makePlayerViewController: () -> NavigationService.PlayerViewController { get }
  var makeSafariViewController: (URL) -> UIViewController { get }
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

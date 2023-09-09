import AVKit
import SafariServices

struct NavigationClient {
  typealias ErrorHandler = (UIViewController, Error) -> Void

  typealias PlayerViewController = UIViewController & AVPlayerViewControllerProtocol

  var makeSearchViewController: () -> UIViewController
  var makeAgendaViewController: (@escaping NavigationClient.ErrorHandler) -> UIViewController
  var makeMapViewController: (@escaping NavigationClient.ErrorHandler) -> UIViewController
  var makeMoreViewController: () -> UIViewController

  var makeEventViewController: (Event) -> UIViewController
  var makePastEventViewController: (Event) -> UIViewController

  var makeTransportationViewController: () -> UIViewController
  var makeVideosViewController: (@escaping NavigationClient.ErrorHandler) -> UIViewController
  var makeInfoViewController: (String, Info, @escaping NavigationClient.ErrorHandler) -> UIViewController

  var makeYearsViewController: (UITableView.Style, @escaping NavigationClient.ErrorHandler) -> UIViewController
  var makeYearViewController: (Int, PersistenceClientProtocol, @escaping NavigationClient.ErrorHandler) -> UIViewController

  var makePlayerViewController: () -> NavigationClient.PlayerViewController
  var makeSafariViewController: (URL) -> UIViewController
}

extension NavigationClient {
  init() {
    makeSearchViewController = {
      let searchController = SearchController()
      searchController.tabBarItem.accessibilityIdentifier = "search"
      searchController.tabBarItem.image = UIImage(systemName: "magnifyingglass")
      searchController.title = L10n.Search.title
      searchController.preferredDisplayMode = .oneBesideSecondary
      searchController.preferredPrimaryColumnWidthFraction = 0.4
      searchController.maximumPrimaryColumnWidth = 375
      return searchController
    }

    makeAgendaViewController = { didError in
      let agendaController = AgendaController()
      agendaController.tabBarItem.accessibilityIdentifier = "agenda"
      agendaController.tabBarItem.image = UIImage(systemName: "calendar")
      agendaController.title = L10n.Agenda.title
      agendaController.didError = didError
      return agendaController
    }

    makeMapViewController = { didError in
      let mapController = MapController()
      mapController.tabBarItem.accessibilityIdentifier = "map"
      mapController.tabBarItem.image = UIImage(systemName: "map")
      mapController.title = L10n.Map.title
      mapController.didError = didError
      return mapController
    }

    makeMoreViewController = {
      let moreController = MoreController()
      moreController.tabBarItem.accessibilityIdentifier = "more"
      moreController.tabBarItem.image = UIImage(systemName: "ellipsis.circle")
      moreController.title = L10n.More.title
      moreController.preferredDisplayMode = .oneBesideSecondary
      moreController.preferredPrimaryColumnWidthFraction = 0.4
      moreController.maximumPrimaryColumnWidth = 375
      return moreController
    }

    makeEventViewController = { event in
      EventController(event: event)
    }

    makePastEventViewController = { event in
      let eventController = EventController(event: event)
      eventController.showsFavoriteButton = false
      return eventController
    }

    makeVideosViewController = { didError in
      let videosController = VideosController()
      videosController.didError = didError
      return videosController
    }

    makeYearsViewController = { style, didError in
      let yearsController = YearsController(style: style)
      yearsController.didError = didError
      return yearsController
    }

    makeYearViewController = { year, persistenceClient, didError in
      let yearController = YearController(persistenceClient: persistenceClient)
      yearController.navigationItem.largeTitleDisplayMode = .never
      yearController.title = year.description
      yearController.didError = didError
      return yearController
    }

    makeInfoViewController = { title, info, didError in
      let infoController = InfoController(info: info)
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
      TransportationController()
    }
  }
}

/// @mockable
protocol NavigationClientProtocol {
  var makeSearchViewController: () -> UIViewController { get }
  var makeAgendaViewController: (@escaping NavigationClient.ErrorHandler) -> UIViewController { get }
  var makeMapViewController: (@escaping NavigationClient.ErrorHandler) -> UIViewController { get }
  var makeMoreViewController: () -> UIViewController { get }

  var makeEventViewController: (Event) -> UIViewController { get }
  var makePastEventViewController: (Event) -> UIViewController { get }

  var makeTransportationViewController: () -> UIViewController { get }
  var makeVideosViewController: (@escaping NavigationClient.ErrorHandler) -> UIViewController { get }
  var makeInfoViewController: (String, Info, @escaping NavigationClient.ErrorHandler) -> UIViewController { get }

  var makeYearsViewController: (UITableView.Style, @escaping NavigationClient.ErrorHandler) -> UIViewController { get }
  var makeYearViewController: (Int, PersistenceClientProtocol, @escaping NavigationClient.ErrorHandler) -> UIViewController { get }

  var makePlayerViewController: () -> NavigationClient.PlayerViewController { get }
  var makeSafariViewController: (URL) -> UIViewController { get }
}

extension NavigationClient: NavigationClientProtocol {}

protocol AVPlayerViewControllerProtocol: AnyObject {
  var delegate: AVPlayerViewControllerDelegate? { get set }
  var exitsFullScreenWhenPlaybackEnds: Bool { get set }
  var player: AVPlayer? { get set }
}

extension AVPlayerViewController: AVPlayerViewControllerProtocol {}

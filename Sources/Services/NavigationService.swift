import UIKit

final class NavigationService {
  typealias ErrorHandler = (UIViewController, Error) -> Void

  private unowned var services: Services!

  init(services: Services) {
    self.services = services
  }
}

extension NavigationService {
  func makeSearchViewController() -> UIViewController {
    let searchController = SearchController(dependencies: services)
    searchController.tabBarItem.accessibilityIdentifier = "search"
    searchController.tabBarItem.image = .fos_systemImage(withName: "magnifyingglass")
    searchController.title = L10n.Search.title
    #if targetEnvironment(macCatalyst)
    searchController.preferredDisplayMode = .oneBesideSecondary
    #else
    searchController.preferredDisplayMode = .allVisible
    #endif
    searchController.preferredPrimaryColumnWidthFraction = 0.4
    searchController.maximumPrimaryColumnWidth = 375
    return searchController
  }

  func makeAgendaViewController(didError: @escaping ErrorHandler) -> UIViewController {
    let agendaController = AgendaController(dependencies: services)
    agendaController.tabBarItem.accessibilityIdentifier = "agenda"
    agendaController.tabBarItem.image = .fos_systemImage(withName: "calendar")
    agendaController.title = L10n.Agenda.title
    agendaController.didError = didError
    return agendaController
  }

  func makeMapViewController(didError: @escaping ErrorHandler) -> UIViewController {
    let mapController = MapController(dependencies: services)
    mapController.tabBarItem.accessibilityIdentifier = "map"
    mapController.tabBarItem.image = .fos_systemImage(withName: "map")
    mapController.title = L10n.Map.title
    mapController.didError = didError
    return mapController
  }

  func makeMoreViewController() -> UIViewController {
    let moreController = MoreController(dependencies: services)
    moreController.tabBarItem.accessibilityIdentifier = "more"
    moreController.tabBarItem.image = .fos_systemImage(withName: "ellipsis.circle")
    moreController.title = L10n.More.title
    #if targetEnvironment(macCatalyst)
    moreController.preferredDisplayMode = .oneBesideSecondary
    #else
    moreController.preferredDisplayMode = .allVisible
    #endif
    moreController.preferredPrimaryColumnWidthFraction = 0.4
    moreController.maximumPrimaryColumnWidth = 375
    return moreController
  }
}

extension NavigationService {
  func makeEventViewController(for event: Event) -> UIViewController {
    let configuration = EventController.Configuration(showsFavoriteButton: true)
    return makeEventViewController(for: event, configuration: configuration)
  }

  func makePastEventViewController(for event: Event) -> UIViewController {
    let configuration = EventController.Configuration(showsFavoriteButton: false)
    return makeEventViewController(for: event, configuration: configuration)
  }

  private func makeEventViewController(for event: Event, configuration: EventController.Configuration) -> UIViewController {
    let eventController = EventController(event: event, dependencies: services)
    let eventViewController = eventController.makeEventViewController(with: configuration)
    eventViewController.fos_controller = eventController
    return eventViewController
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
  func makeYearsViewController(forYear year: String, with persistenceService: PersistenceService, didError: @escaping ErrorHandler) -> UIViewController {
    let yearController = YearController(year: year, yearPersistenceService: persistenceService, dependencies: services)
    yearController.navigationItem.largeTitleDisplayMode = .never
    yearController.didError = didError
    yearController.title = year
    return yearController
  }
}

extension NavigationService {
  func makeInfoViewController(withTitle title: String, info: Info, didError: @escaping ErrorHandler) -> UIViewController {
    let infoController = InfoController(info: info, dependencies: services)
    infoController.accessibilityIdentifier = info.accessibilityIdentifier
    infoController.didError = didError
    infoController.title = title
    return infoController
  }
}

extension NavigationService {
  func makeTransportationViewController() -> UIViewController {
    TransportationController(dependencies: services)
  }
}

private extension UIViewController {
  private static var controllerKey = 0

  var fos_controller: AnyObject? {
    get { objc_getAssociatedObject(self, &UIViewController.controllerKey) as AnyObject? }
    set { objc_setAssociatedObject(self, &UIViewController.controllerKey, newValue as AnyObject?, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
  }
}

/// @mockable
protocol NavigationServiceProtocol {
  func makeSearchViewController() -> UIViewController
  func makeAgendaViewController(didError: @escaping NavigationService.ErrorHandler) -> UIViewController
  func makeMapViewController(didError: @escaping NavigationService.ErrorHandler) -> UIViewController
  func makeMoreViewController() -> UIViewController

  func makeEventViewController(for event: Event) -> UIViewController
  func makePastEventViewController(for event: Event) -> UIViewController

  func makeTransportationViewController() -> UIViewController
  func makeVideosViewController(didError: @escaping NavigationService.ErrorHandler) -> UIViewController
  func makeInfoViewController(withTitle title: String, info: Info, didError: @escaping NavigationService.ErrorHandler) -> UIViewController
  func makeYearsViewController(forYear year: String, with persistenceService: PersistenceService, didError: @escaping NavigationService.ErrorHandler) -> UIViewController
}

extension NavigationService: NavigationServiceProtocol {}

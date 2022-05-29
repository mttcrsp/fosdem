import RIBs
import UIKit

typealias YearDependency = HasEventBuilder & HasSearchBuilder & HasYearsService

typealias YearArguments = Year

protocol YearListener: AnyObject {
  func yearDidError(_ error: Error)
}

protocol HasYearBuilder {
  var yearBuilder: YearBuildable { get }
}

protocol YearBuildable: Buildable {
  func build(with arguments: YearArguments, listener: YearListener) -> YearRouting
}

final class YearBuilder: Builder<YearDependency>, YearBuildable {
  func build(with arguments: YearArguments, listener: YearListener) -> YearRouting {
    let viewController = _YearViewController()
    let interactor = YearInteractor(presenter: viewController, dependency: dependency, arguments: arguments)
    let router = YearRouter(interactor: interactor, viewController: viewController, eventBuilder: dependency.eventBuilder, searchBuilder: dependency.searchBuilder)
    interactor.listener = listener
    interactor.router = router
    viewController.listener = interactor
    return router
  }
}

protocol YearRouting: ViewableRouting {
  func routeToEvent(_ event: Event)
  func routeToSearchResult(_ event: Event)
}

final class YearRouter: ViewableRouter<YearInteractable, YearViewControllable> {
  private var eventRouter: ViewableRouting?
  private var searchResultRouter: ViewableRouting?

  private let eventBuilder: EventBuildable
  private let searchBuilder: SearchBuildable

  init(interactor: YearInteractable, viewController: YearViewControllable, eventBuilder: EventBuildable, searchBuilder: SearchBuildable) {
    self.eventBuilder = eventBuilder
    self.searchBuilder = searchBuilder
    super.init(interactor: interactor, viewController: viewController)
  }

  override func didLoad() {
    super.didLoad()

    let searchRouter = searchBuilder.build(with: interactor)
    attachChild(searchRouter)
    viewController.showSearch(searchRouter.viewControllable)
  }
}

extension YearRouter: YearRouting {
  func routeToEvent(_ event: Event) {
    if let eventRouter = eventRouter {
      detachChild(eventRouter)
      self.eventRouter = nil
    }

    let eventRouter = eventBuilder.build(with: event)
    self.eventRouter = eventRouter
    attachChild(eventRouter)
    viewController.showEvent(eventRouter.viewControllable)
  }

  func routeToSearchResult(_ event: Event) {
    if let searchResultRouter = searchResultRouter {
      detachChild(searchResultRouter)
      self.searchResultRouter = nil
    }

    let searchResultRouter = eventBuilder.build(with: event)
    self.searchResultRouter = searchResultRouter
    attachChild(searchResultRouter)
    viewController.showSearchResult(searchResultRouter.viewControllable)
  }
}

protocol YearInteractable: Interactable, SearchListener {}

final class YearInteractor: PresentableInteractor<YearPresentable>, YearInteractable, YearPresentableListener {
  weak var router: YearRouting?
  weak var listener: YearListener?

  private(set) var tracks: [Track] = []
  private(set) var events: [Event] = []

  private var persistenceService: PersistenceServiceProtocol?

  private let arguments: YearArguments
  private let dependency: YearDependency

  init(presenter: YearPresentable, dependency: YearDependency, arguments: YearArguments) {
    self.arguments = arguments
    self.dependency = dependency
    super.init(presenter: presenter)
  }

  override func didBecomeActive() {
    super.didBecomeActive()

    do {
      persistenceService = try dependency.yearsService.makePersistenceService(forYear: arguments)
    } catch {
      listener?.yearDidError(error)
    }

    persistenceService?.performRead(AllTracksOrderedByName()) { [weak self] result in
      DispatchQueue.main.async {
        switch result {
        case let .success(tracks):
          self?.tracks = tracks
          self?.presenter.reloadData()
        case let .failure(error):
          self?.listener?.yearDidError(error)
        }
      }
    }
  }

  func didSelect(_ track: Track) {
    events = []
    persistenceService?.performRead(EventsForTrack(track: track.name)) { result in
      DispatchQueue.main.async { [weak self] in
        switch result {
        case .failure:
          self?.presenter.showError()
        case let .success(events):
          self?.events = events
          self?.presenter.showEvents(for: track)
        }
      }
    }
  }

  func didSelect(_ event: Event) {
    router?.routeToEvent(event)
  }

  func didSelectResult(_ event: Event) {
    router?.routeToSearchResult(event)
  }

  var year: Year {
    arguments
  }
}

protocol YearPresentableListener: AnyObject {
  var year: Year { get }
  var events: [Event] { get }
  var tracks: [Track] { get }
  func didSelect(_ event: Event)
  func didSelect(_ track: Track)
}

protocol YearViewControllable: ViewControllable {
  func showEvent(_ eventViewControllable: ViewControllable)
  func showSearch(_ searchViewControllable: ViewControllable)
  func showSearchResult(_ eventViewController: ViewControllable)
}

protocol YearPresentable: Presentable {
  func reloadData()
  func showError()
  func showEvents(for track: Track)
}

final class _YearViewController: TracksViewController, YearPresentable, YearViewControllable {
  weak var listener: YearPresentableListener?

  private weak var eventsViewController: EventsViewController?
  private var searchController: UISearchController?

  override func viewDidLoad() {
    super.viewDidLoad()

    delegate = self
    dataSource = self
    definesPresentationContext = true
    view.backgroundColor = .groupTableViewBackground
    navigationItem.largeTitleDisplayMode = .never
    title = listener?.year.description
  }

  func showEvents(for track: Track) {
    let eventsViewController = EventsViewController(style: .grouped)
    eventsViewController.title = track.name
    eventsViewController.dataSource = self
    eventsViewController.delegate = self
    self.eventsViewController = eventsViewController
  }

  func showEvent(_ eventViewControllable: ViewControllable) {
    let eventViewController = eventViewControllable.uiviewController
    eventsViewController?.show(eventViewController, sender: nil)
  }

  func showError() {
    let errorViewController = UIAlertController.makeErrorController()
    present(errorViewController, animated: true)
  }

  func showSearch(_ searchViewControllable: ViewControllable) {
    if let searchController = searchViewControllable.uiviewController as? UISearchController {
      addSearchViewController(searchController)
    }
  }

  func showSearchResult(_ eventViewControllable: ViewControllable) {
    let resultViewController = eventViewControllable.uiviewController
    show(resultViewController, sender: nil)
  }
}

extension _YearViewController: TracksViewControllerDataSource, TracksViewControllerDelegate {
  private var events: [Event] {
    listener?.events ?? []
  }

  private var tracks: [Track] {
    listener?.tracks ?? []
  }

  func numberOfSections(in _: TracksViewController) -> Int {
    1
  }

  func tracksViewController(_: TracksViewController, numberOfTracksIn _: Int) -> Int {
    tracks.count
  }

  func tracksViewController(_: TracksViewController, trackAt indexPath: IndexPath) -> Track {
    tracks[indexPath.row]
  }

  func tracksViewController(_: TracksViewController, didSelect track: Track) {
    listener?.didSelect(track)
  }
}

extension _YearViewController: EventsViewControllerDataSource, EventsViewControllerDelegate {
  func events(in _: EventsViewController) -> [Event] {
    listener?.events ?? []
  }

  func eventsViewController(_: EventsViewController, captionFor event: Event) -> String? {
    event.formattedPeople
  }

  func eventsViewController(_: EventsViewController, didSelect event: Event) {
    listener?.didSelect(event)
  }
}

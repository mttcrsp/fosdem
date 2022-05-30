import Dispatch
import RIBs

protocol YearRouting: ViewableRouting {
  func routeToEvent(_ event: Event)
  func routeToSearchResult(_ event: Event)
}

protocol YearPresentable: Presentable {
  func reloadData()
  func showError()
  func showEvents(for track: Track)
}

protocol YearListener: AnyObject {
  func yearDidError(_ error: Error)
}

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

  func select(_ track: Track) {
    events = []
    persistenceService?.performRead(EventsForTrack(track: track.name)) { [weak self] result in
      DispatchQueue.main.async {
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

  func select(_ event: Event) {
    router?.routeToEvent(event)
  }

  func didSelectResult(_ event: Event) {
    router?.routeToSearchResult(event)
  }

  var year: Year {
    arguments
  }
}

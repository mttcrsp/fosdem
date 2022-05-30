import Dispatch
import RIBs

protocol YearRouting: ViewableRouting {
  func routeToEvent(_ event: Event)
  func routeToSearchResult(_ event: Event)
}

protocol YearPresentable: Presentable {
  var year: Year? { get set }
  var tracks: [Track] { get set }
  var events: [Event] { get set }

  func showError()
  func showEvents(for track: Track)
}

protocol YearListener: AnyObject {
  func yearDidError(_ error: Error)
}

final class YearInteractor: PresentableInteractor<YearPresentable> {
  weak var router: YearRouting?
  weak var listener: YearListener?

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

    presenter.year = arguments.year

    do {
      persistenceService = try dependency.yearsService.makePersistenceService(forYear: arguments.year)
    } catch {
      listener?.yearDidError(error)
    }

    persistenceService?.performRead(AllTracksOrderedByName()) { [weak self] result in
      DispatchQueue.main.async {
        switch result {
        case let .failure(error):
          self?.listener?.yearDidError(error)
        case let .success(tracks):
          self?.presenter.tracks = tracks
        }
      }
    }
  }
}

extension YearInteractor: YearPresentableListener {
  func select(_ track: Track) {
    persistenceService?.performRead(EventsForTrack(track: track.name)) { [weak self] result in
      DispatchQueue.main.async {
        switch result {
        case .failure:
          self?.presenter.showError()
        case let .success(events):
          self?.presenter.events = events
          self?.presenter.showEvents(for: track)
        }
      }
    }
  }

  func select(_ event: Event) {
    router?.routeToEvent(event)
  }
}

extension YearInteractor: YearInteractable {
  func didSelectResult(_ event: Event) {
    router?.routeToSearchResult(event)
  }
}

import Dispatch
import RIBs

protocol YearRouting: ViewableRouting {
  func attachSearch(_ arguments: SearchArguments)
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
  private let services: YearServices

  init(arguments: YearArguments, presenter: YearPresentable, services: YearServices) {
    self.arguments = arguments
    self.services = services
    super.init(presenter: presenter)
  }

  override func didBecomeActive() {
    super.didBecomeActive()

    presenter.year = arguments.year

    do {
      let persistenceService = try services.yearsService.makePersistenceService(forYear: arguments.year)
      self.persistenceService = persistenceService

      let arguments = SearchArguments(
        persistenceService: persistenceService,
        favoritesService: nil
      )
      router?.attachSearch(arguments)
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

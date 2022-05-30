import Foundation
import RIBs

protocol AgendaRouting: Routing {
  func routeToEvent(_ event: Event?)
  func routeToSoon()
  func routeBackFromSoon()
}

protocol AgendaPresentable: Presentable {
  var events: [Event] { get set }
  func performEventsUpdate(_ updates: () -> Void)
  func insertEvent(at index: Int)
  func removeEvent(at index: Int)
  func reloadEvents()
  func reloadLiveStatus()
  func showError()
}

final class AgendaInteractor: PresentableInteractor<AgendaPresentable> {
  weak var listener: AgendaListener?
  weak var router: AgendaRouting?

  private(set) var selectedEvent: Event?

  private var favoritesObserver: NSObjectProtocol?
  private var timeObserver: NSObjectProtocol?

  let dependency: AgendaDependency

  init(dependency: AgendaDependency, presenter: AgendaPresentable) {
    self.dependency = dependency
    super.init(presenter: presenter)
  }

  override func didBecomeActive() {
    super.didBecomeActive()

    loadFavoriteEvents { [weak self] events in
      self?.presenter.events = events
      self?.presenter.reloadEvents()
    }

    favoritesObserver = dependency.favoritesService.addObserverForEvents { [weak self] id in
      self?.loadFavoriteEvents { events in
        guard let self = self else { return }

        self.presenter.performEventsUpdate {
          defer { self.presenter.events = events }

          if let index = self.presenter.events.firstIndex(where: { event in event.id == id }) {
            self.presenter.removeEvent(at: index)
          } else if let index = events.firstIndex(where: { event in event.id == id }) {
            self.presenter.insertEvent(at: index)
          }
        }
      }
    }

    timeObserver = dependency.timeService.addObserver { [weak self] in
      self?.presenter.reloadLiveStatus()
    }
  }

  override func willResignActive() {
    super.willResignActive()

    if let favoritesObserver = favoritesObserver {
      dependency.favoritesService.removeObserver(favoritesObserver)
    }

    if let timeObserver = timeObserver {
      dependency.timeService.removeObserver(timeObserver)
    }
  }
}

extension AgendaInteractor: AgendaPresentableListener {
  func select(_ selectedEvent: Event?) {
    router?.routeToEvent(selectedEvent)
  }

  func selectFirstEvent() {
    if let event = presenter.events.first {
      select(event)
    }
  }

  func selectSoon() {
    router?.routeToSoon()
  }

  func isLive(_ event: Event) -> Bool {
    event.isLive(at: dependency.timeService.now)
  }

  func canFavorite(_ event: Event) -> Bool {
    !dependency.favoritesService.contains(event)
  }

  func toggleFavorite(_ event: Event) {
    if canFavorite(event) {
      dependency.favoritesService.addEvent(withIdentifier: event.id)
    } else {
      dependency.favoritesService.removeEvent(withIdentifier: event.id)
    }

    if event == selectedEvent {
      selectFirstEvent()
    }
  }
}

extension AgendaInteractor: AgendaInteractable {
  func soonDidError(_: Error) {
    router?.routeBackFromSoon()
    presenter.showError()
  }

  func soonDidDismiss() {
    router?.routeBackFromSoon()
  }
}

private extension AgendaInteractor {
  func loadFavoriteEvents(completion: @escaping ([Event]) -> Void) {
    let identifiers = dependency.favoritesService.eventsIdentifiers
    let operation = EventsForIdentifiers(identifiers: identifiers)
    dependency.persistenceService.performRead(operation) { [weak self] result in
      DispatchQueue.main.async {
        switch result {
        case let .failure(error):
          self?.listener?.agendaDidError(error)
        case let .success(events):
          completion(events)
        }
      }
    }
  }
}

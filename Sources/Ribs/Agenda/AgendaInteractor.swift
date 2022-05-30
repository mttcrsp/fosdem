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

    reloadFavoriteEvents()

    favoritesObserver = dependency.favoritesService.addObserverForEvents { [weak self] identifier in
      self?.reloadFavoriteEvents(forUpdateToEventWithIdentifier: identifier)
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

  private func reloadFavoriteEvents(forUpdateToEventWithIdentifier updatedID: Int? = nil) {
    let identifiers = dependency.favoritesService.eventsIdentifiers
    let operation = EventsForIdentifiers(identifiers: identifiers)
    dependency.persistenceService.performRead(operation) { [weak self] result in
      DispatchQueue.main.async {
        guard let self = self else { return }

        switch result {
        case let .failure(error):
          self.listener?.agendaDidError(error)
        case let .success(events):
          if let updatedID = updatedID {
            self.presenter.performEventsUpdate {
              if let index = self.presenter.events.firstIndex(where: { $0.id == updatedID }) {
                self.presenter.removeEvent(at: index)
              } else if let index = events.firstIndex(where: { $0.id == updatedID }) {
                self.presenter.insertEvent(at: index)
              }
              self.presenter.events = events
            }
          } else {
            self.presenter.events = events
            self.presenter.reloadEvents()
          }
        }
      }
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

  func canFavoriteEvent(_ event: Event) -> Bool {
    !dependency.favoritesService.contains(event)
  }

  func toggleFavorite(_ event: Event) {
    if canFavoriteEvent(event) {
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

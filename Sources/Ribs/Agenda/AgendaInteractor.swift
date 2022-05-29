import Foundation
import RIBs

protocol AgendaRouting: Routing {
  func routeToAgendaEvent(_ event: Event)
  func routeToSoonEvent(_ event: Event?)
}

protocol AgendaPresentable: Presentable {
  func reloadLiveStatus()
  func showError()
  func showSoonEvents(_ events: [Event])
  func showAgendaEvents(_ events: [Event], withUpdatedEventIdentifier identifier: Int?)
}

final class AgendaInteractor: PresentableInteractor<AgendaPresentable> {
  weak var listener: AgendaListener?
  weak var router: AgendaRouting?

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
  }

  private func reloadFavoriteEvents(forUpdateToEventWithIdentifier identifier: Int? = nil) {
    let identifiers = dependency.favoritesService.eventsIdentifiers
    let operation = EventsForIdentifiers(identifiers: identifiers)
    dependency.persistenceService.performRead(operation) { result in
      DispatchQueue.main.async { [weak self] in
        switch result {
        case let .failure(error):
          self?.listener?.agendaDidError(error)
        case let .success(events):
          self?.presenter.showAgendaEvents(events, withUpdatedEventIdentifier: identifier)
        }
      }
    }
  }
}

extension AgendaInteractor: AgendaPresentableListener {
  func didSelectAgendaEvent(_ event: Event) {
    router?.routeToAgendaEvent(event)
  }

  func didSelectSoon() {
    dependency.soonService.loadEvents { result in
      DispatchQueue.main.async { [weak self] in
        switch result {
        case .failure:
          self?.presenter.showError()
        case let .success(events):
          self?.presenter.showSoonEvents(events)
        }
      }
    }
  }

  func didSelectSoonEvent(_ event: Event) {
    router?.routeToSoonEvent(event)
  }

  func didDeselectSoonEvent() {
    router?.routeToSoonEvent(nil)
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
  }

  func shouldShowLiveIndicator(for event: Event) -> Bool {
    event.isLive(at: dependency.timeService.now)
  }
}

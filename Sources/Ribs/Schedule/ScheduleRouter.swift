import RIBs

protocol ScheduleViewControllable: ViewControllable {
  func addSearch(_ viewController: ViewControllable)
  func showTrack(_ viewControllable: ViewControllable)
  func showSearchResult(_ eventViewController: ViewControllable)
}

protocol ScheduleInteractable: Interactable, SearchListener, TrackListener {}

final class ScheduleRouter: ViewableRouter<ScheduleInteractable, ScheduleViewControllable> {
  private var trackRouter: ViewableRouting?
  private var searchResultRouter: ViewableRouting?

  private let component: ScheduleComponent

  init(component: ScheduleComponent, interactor: ScheduleInteractable, viewController: ScheduleViewControllable) {
    self.component = component
    super.init(interactor: interactor, viewController: viewController)
  }
}

extension ScheduleRouter: ScheduleRouting {
  func attachSearch(_ arguments: SearchArguments) {
    let searchRouter = component.buildSearchRouter(withArguments: arguments, listener: interactor)
    attachChild(searchRouter)
    viewController.addSearch(searchRouter.viewControllable)
  }

  func routeToTrack(_ track: Track?) {
    if let trackRouter = trackRouter {
      detachChild(trackRouter)
      self.trackRouter = nil
    }

    if let track = track {
      let trackRouter = component.buildTrackRouter(withArguments: .init(track: track), listener: interactor)
      self.trackRouter = trackRouter
      attachChild(trackRouter)
      viewController.showTrack(trackRouter.viewControllable)
    }
  }

  func routeToSearchResult(_ event: Event) {
    if let searchResultRouter = searchResultRouter {
      detachChild(searchResultRouter)
      self.searchResultRouter = nil
    }

    let searchResultRouter = component.buildEventRouter(withArguments: .init(event: event))
    self.searchResultRouter = searchResultRouter
    attachChild(searchResultRouter)
    viewController.showSearchResult(searchResultRouter.viewControllable)
  }

  func routeBackFromSearchResult() {
    if let searchResultRouter = searchResultRouter {
      detachChild(searchResultRouter)
      self.searchResultRouter = nil
    }
  }
}

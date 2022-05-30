import RIBs

protocol ScheduleViewControllable: ViewControllable {
  func addSearch(_ viewController: ViewControllable)
  func showDetail(_ viewControllable: ViewControllable)
  func showSearchResult(_ eventViewController: ViewControllable)
}

protocol ScheduleInteractable: Interactable, SearchListener, TrackListener {}

final class ScheduleRouter: ViewableRouter<ScheduleInteractable, ScheduleViewControllable> {
  private var trackRouter: ViewableRouting?
  private var searchResultRouter: ViewableRouting?

  private let eventBuilder: EventBuildable
  private let trackBuilder: TrackBuildable
  private let searchBuilder: SearchBuildable

  init(interactor: ScheduleInteractable, viewController: ScheduleViewControllable, eventBuilder: EventBuildable, trackBuilder: TrackBuildable, searchBuilder: SearchBuildable) {
    self.eventBuilder = eventBuilder
    self.trackBuilder = trackBuilder
    self.searchBuilder = searchBuilder
    super.init(interactor: interactor, viewController: viewController)
  }

  override func didLoad() {
    super.didLoad()

    let searchRouter = searchBuilder.build(withListener: interactor)
    attachChild(searchRouter)
    viewController.addSearch(searchRouter.viewControllable)
  }
}

extension ScheduleRouter: ScheduleRouting {
  func routeToTrack(_ track: Track) {
    if let trackRouter = trackRouter {
      detachChild(trackRouter)
      self.trackRouter = nil
    }

    let trackRouter = trackBuilder.build(withListener: interactor, arguments: .init(track: track))
    self.trackRouter = trackRouter
    attachChild(trackRouter)
    viewController.showDetail(trackRouter.viewControllable)
  }

  func routeToSearchResult(_ event: Event) {
    if let searchResultRouter = searchResultRouter {
      detachChild(searchResultRouter)
      self.searchResultRouter = nil
    }

    let searchResultRouter = eventBuilder.build(with: .init(event: event))
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

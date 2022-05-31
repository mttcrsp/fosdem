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

  private let builders: ScheduleBuilders

  init(builders: ScheduleBuilders, interactor: ScheduleInteractable, viewController: ScheduleViewControllable) {
    self.builders = builders
    super.init(interactor: interactor, viewController: viewController)
  }

  override func didLoad() {
    super.didLoad()

    let searchRouter = builders.searchBuilder.build(withListener: interactor)
    attachChild(searchRouter)
    viewController.addSearch(searchRouter.viewControllable)
  }
}

extension ScheduleRouter: ScheduleRouting {
  func routeToTrack(_ track: Track?) {
    if let trackRouter = trackRouter {
      detachChild(trackRouter)
      self.trackRouter = nil
    }

    if let track = track {
      let trackRouter = builders.trackBuilder.build(withListener: interactor, arguments: .init(track: track))
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

    let searchResultRouter = builders.eventBuilder.build(with: .init(event: event))
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

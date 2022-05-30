import RIBs

protocol ScheduleViewControllable: ViewControllable {
  func addSearch(_ eventViewController: ViewControllable)
  func showEvent(_ eventViewController: ViewControllable)
  func showSearchResult(_ eventViewController: ViewControllable)
}

final class ScheduleRouter: ViewableRouter<ScheduleInteractable, ScheduleViewControllable> {
  private var eventRouter: ViewableRouting?
  private var searchResultRouter: ViewableRouting?

  private let eventBuilder: EventBuildable
  private let searchBuilder: SearchBuildable

  init(interactor: ScheduleInteractable, viewController: ScheduleViewControllable, eventBuilder: EventBuildable, searchBuilder: SearchBuildable) {
    self.eventBuilder = eventBuilder
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
  func routeToEvent(_ event: Event?) {
    if let eventRouter = eventRouter {
      detachChild(eventRouter)
      self.eventRouter = nil
    }

    if let event = event {
      let eventRouter = eventBuilder.build(with: .init(event: event))
      self.eventRouter = eventRouter
      attachChild(eventRouter)
      viewController.showEvent(eventRouter.viewControllable)
    }
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

protocol ScheduleInteractable: Interactable, SearchListener {}

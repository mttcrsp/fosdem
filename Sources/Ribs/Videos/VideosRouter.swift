import RIBs

protocol VideosViewControllable: ViewControllable {
  func showEvent(_ eventViewControllable: ViewControllable)
}

final class VideosRouter: ViewableRouter<Interactable, VideosViewControllable> {
  private var eventRouter: ViewableRouting?

  private let eventBuilder: EventBuildable

  init(interactor: Interactable, viewController: VideosViewControllable, eventBuilder: EventBuildable) {
    self.eventBuilder = eventBuilder
    super.init(interactor: interactor, viewController: viewController)
  }
}

extension VideosRouter: VideosRouting {
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
}

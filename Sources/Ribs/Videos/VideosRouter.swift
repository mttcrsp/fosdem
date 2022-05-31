import RIBs

protocol VideosViewControllable: ViewControllable {
  func showEvent(_ eventViewControllable: ViewControllable)
}

final class VideosRouter: ViewableRouter<Interactable, VideosViewControllable> {
  private var eventRouter: ViewableRouting?

  private let builders: VideosBuilders

  init(builders: VideosBuilders, interactor: Interactable, viewController: VideosViewControllable) {
    self.builders = builders
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
      let eventRouter = builders.eventBuilder.build(with: .init(event: event))
      self.eventRouter = eventRouter
      attachChild(eventRouter)
      viewController.showEvent(eventRouter.viewControllable)
    }
  }
}

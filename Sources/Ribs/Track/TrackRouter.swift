import RIBs

protocol TrackViewControllable: ViewControllable {
  func show(_ viewControllable: ViewControllable)
}

final class TrackRouter: ViewableRouter<Interactable, TrackViewControllable> {
  private var eventRouter: ViewableRouting?

  private let eventBuilder: EventBuildable

  init(interactor: Interactable, viewController: TrackViewControllable, eventBuilder: EventBuildable) {
    self.eventBuilder = eventBuilder
    super.init(interactor: interactor, viewController: viewController)
  }
}

extension TrackRouter: TrackRouting {
  func routeToEvent(_ event: Event?) {
    if let eventRouter = eventRouter {
      detachChild(eventRouter)
      self.eventRouter = nil
    }

    if let event = event {
      let eventRouter = eventBuilder.build(with: .init(event: event))
      self.eventRouter = eventRouter
      attachChild(eventRouter)
      viewController.show(eventRouter.viewControllable)
    }
  }
}

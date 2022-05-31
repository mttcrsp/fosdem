import RIBs

protocol TrackViewControllable: ViewControllable {
  func show(_ viewControllable: ViewControllable)
}

final class TrackRouter: ViewableRouter<Interactable, TrackViewControllable> {
  private var eventRouter: ViewableRouting?

  private let builders: TrackBuilders

  init(builders: TrackBuilders, interactor: Interactable, viewController: TrackViewControllable) {
    self.builders = builders
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
      let eventRouter = builders.eventBuilder.build(with: .init(event: event))
      self.eventRouter = eventRouter
      attachChild(eventRouter)
      viewController.show(eventRouter.viewControllable)
    }
  }
}

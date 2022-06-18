import RIBs

protocol TrackViewControllable: ViewControllable {
  func showEvent(_ viewControllable: ViewControllable)
}

final class TrackRouter: ViewableRouter<Interactable, TrackViewControllable> {
  private var eventRouter: ViewableRouting?

  private let component: TrackComponent

  init(component: TrackComponent, interactor: Interactable, viewController: TrackViewControllable) {
    self.component = component
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
      let eventRouter = component.eventBuilder.build(with: .init(event: event))
      self.eventRouter = eventRouter
      attachChild(eventRouter)
      viewController.showEvent(eventRouter.viewControllable)
    }
  }
}

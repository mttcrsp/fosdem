import RIBs

protocol SoonViewControllable: ViewControllable {
  func push(_ viewControllable: ViewControllable)
}

final class SoonRouter: ViewableRouter<Interactable, SoonViewControllable> {
  private var eventRouter: Routing?

  private let eventBuilder: EventBuildable

  init(interactor: Interactable, viewController: SoonViewControllable, eventBuilder: EventBuildable) {
    self.eventBuilder = eventBuilder
    super.init(interactor: interactor, viewController: viewController)
  }
}

extension SoonRouter: SoonRouting {
  func routeToEvent(_ event: Event?) {
    if let eventRouter = eventRouter {
      detachChild(eventRouter)
      self.eventRouter = nil
    }

    if let event = event {
      let eventRouter = eventBuilder.build(with: .init(event: event))
      self.eventRouter = eventRouter
      attachChild(eventRouter)
      viewController.push(eventRouter.viewControllable)
    }
  }
}

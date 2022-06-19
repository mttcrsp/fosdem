import RIBs

protocol SoonViewControllable: ViewControllable {
  func push(_ viewControllable: ViewControllable)
}

final class SoonRouter: ViewableRouter<Interactable, SoonViewControllable> {
  private var eventRouter: Routing?

  private let component: SoonComponent

  init(component: SoonComponent, interactor: Interactable, viewController: SoonViewControllable) {
    self.component = component
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
      let eventRouter = component.buildEventRouter(withArguments: .init(event: event))
      self.eventRouter = eventRouter
      attachChild(eventRouter)
      viewController.push(eventRouter.viewControllable)
    }
  }
}

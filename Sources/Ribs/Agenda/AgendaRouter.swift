import RIBs

protocol AgendaViewControllable: ViewControllable {
  func showDetail(_ viewControllable: ViewControllable)
  func present(_ viewControllable: ViewControllable)
  func dismiss(_ viewControllable: ViewControllable)
}

protocol AgendaInteractable: Interactable, SoonListener {}

final class AgendaRouter: ViewableRouter<AgendaInteractable, AgendaViewControllable>, AgendaRouting {
  private var eventRouter: ViewableRouting?
  private var soonRouter: ViewableRouting?

  private let component: AgendaComponent

  init(component: AgendaComponent, interactor: AgendaInteractable, viewController: AgendaViewControllable) {
    self.component = component
    super.init(interactor: interactor, viewController: viewController)
  }

  func routeToEvent(_ event: Event?) {
    if let eventRouter = eventRouter {
      detachChild(eventRouter)
      self.eventRouter = nil
    }

    if let event = event {
      let eventRouter = component.eventBuilder.finalStageBuild(withDynamicDependency: .init(event: event))
      self.eventRouter = eventRouter
      attachChild(eventRouter)
      viewController.showDetail(eventRouter.viewControllable)
    }
  }

  func routeToSoon() {
    let soonRouter = component.soonBuilder.finalStageBuild(withDynamicDependency: interactor)
    self.soonRouter = soonRouter
    attachChild(soonRouter)
    viewController.present(soonRouter.viewControllable)
  }

  func routeBackFromSoon() {
    if let soonRouter = soonRouter {
      self.soonRouter = nil
      detachChild(soonRouter)
      viewController.dismiss(soonRouter.viewControllable)
    }
  }
}

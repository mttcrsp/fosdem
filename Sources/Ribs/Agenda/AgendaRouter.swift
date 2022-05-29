import RIBs

protocol AgendaViewControllable: ViewControllable {
  func showAgendaEvent(_ event: Event, with viewControllable: ViewControllable)
  func showSoonEvent(_ event: Event, with viewControllable: ViewControllable)
}

final class AgendaRouter: ViewableRouter<Interactable, AgendaViewControllable>, AgendaRouting {
  private var agendaEventRouter: ViewableRouting?
  private var soonEventRouter: ViewableRouting?

  private let eventBuilder: EventBuildable

  init(interactor: Interactable, viewController: AgendaViewControllable, eventBuilder: EventBuildable) {
    self.eventBuilder = eventBuilder
    super.init(interactor: interactor, viewController: viewController)
  }

  func routeToAgendaEvent(_ event: Event) {
    if let router = agendaEventRouter {
      detachChild(router)
      agendaEventRouter = nil
    }

    let router = eventBuilder.build(with: .init(event: event))
    attachChild(router)
    viewController.showAgendaEvent(event, with: router.viewControllable)
    agendaEventRouter = router
  }

  func routeToSoonEvent(_ event: Event?) {
    if let event = event {
      let router = eventBuilder.build(with: .init(event: event))
      attachChild(router)
      viewController.showSoonEvent(event, with: router.viewControllable)
      soonEventRouter = router
    } else if let router = soonEventRouter {
      detachChild(router)
      soonEventRouter = nil
    }
  }
}

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

  private let builders: AgendaBuilders

  init(builders: AgendaBuilders, interactor: AgendaInteractable, viewController: AgendaViewControllable) {
    self.builders = builders
    super.init(interactor: interactor, viewController: viewController)
  }

  func routeToEvent(_ event: Event?) {
    if let router = eventRouter {
      detachChild(router)
      eventRouter = nil
    }

    if let event = event {
      let router = builders.eventBuilder.build(with: .init(event: event))
      attachChild(router)
      viewController.showDetail(router.viewControllable)
      eventRouter = router
    }
  }

  func routeToSoon() {
    let soonRouter = builders.soonBuilder.build(withListener: interactor)
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

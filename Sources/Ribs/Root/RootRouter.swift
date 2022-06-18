import RIBs

protocol RootInteractable: Interactable, AgendaListener, MapListener {}

protocol RootViewControllable: ViewControllable {
  func addAgenda(_ agendaViewControllable: ViewControllable)
  func addMap(_ mapViewControllable: ViewControllable)
  func addMore(_ mapViewControllable: ViewControllable)
  func addSchedule(_ scheduleViewControllable: ViewControllable)
  func removeAgenda()
  func removeMap()
}

class RootRouter: LaunchRouter<RootInteractable, RootViewControllable> {
  private var agendaRouter: ViewableRouting?
  private var mapRouter: ViewableRouting?
  private var moreRouter: ViewableRouting?
  private var scheduleRouter: ViewableRouting?

  private let builders: RootBuilders

  init(builders: RootBuilders, interactor: RootInteractable, viewController: RootViewControllable) {
    self.builders = builders
    super.init(interactor: interactor, viewController: viewController)
  }

  func attach(withServices services: Services) {
    let scheduleRouter = builders.scheduleBuilder.build(withDynamicDependency: services)
    self.scheduleRouter = scheduleRouter
    attachChild(scheduleRouter)
    viewController.addSchedule(scheduleRouter.viewControllable)

    let agendaRouter = builders.agendaBuilder.build(withDynamicDependency: services, listener: interactor)
    self.agendaRouter = agendaRouter
    attachChild(agendaRouter)
    viewController.addAgenda(agendaRouter.viewControllable)

    let moreRouter = builders.moreBuilder.build(withDynamicDependency: services)
    self.moreRouter = moreRouter
    attachChild(moreRouter)
    viewController.addMore(moreRouter.viewControllable)

    let mapRouter = builders.mapBuilder.build(withDynamicDependency: services, listener: interactor)
    self.mapRouter = mapRouter
    attachChild(mapRouter)
    viewController.addMap(mapRouter.viewControllable)
  }
}

extension RootRouter: RootRouting {
  func removeAgenda() {
    if let agendaRouter = agendaRouter {
      detachChild(agendaRouter)
      viewController.removeAgenda()
    }
  }

  func removeMap() {
    if let mapRouter = mapRouter {
      detachChild(mapRouter)
      viewController.removeMap()
    }
  }
}

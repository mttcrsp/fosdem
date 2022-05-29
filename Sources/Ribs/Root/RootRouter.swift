import RIBs

protocol RootInteractable: Interactable, AgendaListener, MapListener {}

protocol RootViewControllable: ViewControllable {
  func addAgenda(_ agendaViewControllable: ViewControllable)
  func addMap(_ mapViewControllable: ViewControllable)
  func addMore(_ mapViewControllable: ViewControllable)
  func addSchedule(_ scheduleViewControllable: ViewControllable)
  func removeAgenda()
  func removeMap()
  func removeSchedule()
}

class RootRouter: LaunchRouter<RootInteractable, RootViewControllable> {
  private var agendaRouter: ViewableRouting?
  private var mapRouter: ViewableRouting?
  private var moreRouter: ViewableRouting?
  private var scheduleRouter: ViewableRouting?

  private let agendaBuilder: AgendaBuildable
  private let mapBuilder: MapBuildable
  private let moreBuilder: MoreBuildable
  private let scheduleBuilder: ScheduleBuildable

  init(
    interactor: RootInteractable,
    viewController: RootViewControllable,
    agendaBuilder: AgendaBuildable,
    mapBuilder: MapBuildable,
    moreBuilder: MoreBuildable,
    scheduleBuilder: ScheduleBuildable
  ) {
    self.agendaBuilder = agendaBuilder
    self.mapBuilder = mapBuilder
    self.moreBuilder = moreBuilder
    self.scheduleBuilder = scheduleBuilder
    super.init(interactor: interactor, viewController: viewController)
  }

  override func didLoad() {
    super.didLoad()

    let scheduleRouter = scheduleBuilder.build()
    self.scheduleRouter = scheduleRouter
    attachChild(scheduleRouter)
    viewController.addSchedule(scheduleRouter.viewControllable)

    let agendaRouter = agendaBuilder.build(with: interactor)
    self.agendaRouter = agendaRouter
    attachChild(agendaRouter)
    viewController.addAgenda(agendaRouter.viewControllable)

    let moreRouter = moreBuilder.build()
    self.moreRouter = moreRouter
    attachChild(moreRouter)
    viewController.addMore(moreRouter.viewControllable)

    let mapRouter = mapBuilder.build(with: interactor)
    self.mapRouter = mapRouter
    attachChild(mapRouter)
    viewController.addMap(mapRouter.viewControllable)
  }
}

extension RootRouter: RootRouting {
  func removeAgenda() {
    viewController.removeAgenda()
  }

  func removeMap() {
    viewController.removeMap()
  }
}

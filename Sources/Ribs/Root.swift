import RIBs
import UIKit

protocol HasAgendaBuilder {
  var agendaBuilder: AgendaBuildable { get }
}

protocol HasMapBuilder {
  var mapBuilder: MapBuildable { get }
}

protocol HasMoreBuilder {
  var moreBuilder: MoreBuildable { get }
}

protocol HasScheduleBuilder {
  var scheduleBuilder: ScheduleBuildable { get }
}

typealias RootDependency = HasAgendaBuilder
  & HasMapBuilder
  & HasMoreBuilder
  & HasScheduleBuilder

protocol RootBuildable: Buildable {
  func build() -> LaunchRouting
}

class RootBuilder: Builder<RootDependency> {
  func build() -> LaunchRouting {
    let viewController = RootViewController()
    let interactor = RootInteractor()
    let router = RootRouter(
      interactor: interactor,
      viewController: viewController,
      agendaBuilder: dependency.agendaBuilder,
      mapBuilder: dependency.mapBuilder,
      moreBuilder: dependency.moreBuilder,
      scheduleBuilder: dependency.scheduleBuilder
    )
    interactor.router = router
    return router
  }
}

protocol RootRouting: Routing {
  func removeAgenda()
  func removeMap()
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

protocol RootInteractable: Interactable, AgendaListener, MapListener {}

class RootInteractor: Interactor {
  var router: RootRouting?
}

extension RootInteractor: RootInteractable {
  func agendaDidError(_: Error) {
    router?.removeAgenda()
    // TODO: show error if needed?
  }

  func mapDidError(_: Error) {
    router?.removeMap()
    // TODO: show error if needed?
  }
}

protocol RootViewControllable: ViewControllable {
  func addAgenda(_ agendaViewControllable: ViewControllable)
  func addMap(_ mapViewControllable: ViewControllable)
  func addMore(_ mapViewControllable: ViewControllable)
  func addSchedule(_ scheduleViewControllable: ViewControllable)
  func removeAgenda()
  func removeMap()
  func removeSchedule()
}

class RootViewController: UITabBarController {
  private var agendaViewController: UIViewController? {
    didSet { didChangeViewControllers() }
  }

  private var mapViewController: UIViewController? {
    didSet { didChangeViewControllers() }
  }

  private var moreViewController: UIViewController? {
    didSet { didChangeViewControllers() }
  }

  private var scheduleViewController: UIViewController? {
    didSet { didChangeViewControllers() }
  }

  private func didChangeViewControllers() {
    let viewControllers = [scheduleViewController, agendaViewController, mapViewController, moreViewController]
    self.viewControllers = viewControllers.compactMap { $0 }
  }
}

extension RootViewController: RootViewControllable {
  func addAgenda(_ agendaViewControllable: ViewControllable) {
    agendaViewController = agendaViewControllable.uiviewController
    agendaViewController?.title = L10n.Agenda.title
    agendaViewController?.tabBarItem.accessibilityIdentifier = "agenda"
    agendaViewController?.tabBarItem.image = .fos_systemImage(withName: "calendar")
  }

  func addMap(_ mapViewControllable: ViewControllable) {
    mapViewController = mapViewControllable.uiviewController
    mapViewController?.title = L10n.Map.title
    mapViewController?.tabBarItem.accessibilityIdentifier = "map"
    mapViewController?.tabBarItem.image = .fos_systemImage(withName: "map")
  }

  func addMore(_ mapViewControllable: ViewControllable) {
    moreViewController = mapViewControllable.uiviewController
    moreViewController?.title = L10n.More.title
    moreViewController?.tabBarItem.accessibilityIdentifier = "more"
    moreViewController?.tabBarItem.image = .fos_systemImage(withName: "ellipsis.circle")
  }

  func addSchedule(_ scheduleViewControllable: ViewControllable) {
    scheduleViewController = scheduleViewControllable.uiviewController
    scheduleViewController?.title = L10n.Search.title
    scheduleViewController?.tabBarItem.accessibilityIdentifier = "search"
    scheduleViewController?.tabBarItem.image = .fos_systemImage(withName: "magnifyingglass")
  }

  func removeAgenda() {
    agendaViewController = nil
  }

  func removeMap() {
    mapViewController = nil
  }

  func removeSchedule() {
    scheduleViewController = nil
  }
}

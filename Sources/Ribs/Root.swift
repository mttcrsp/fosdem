import RIBs
import UIKit

protocol HasAgendaBuilder {
  var agendaBuilder: AgendaBuildable { get }
}

protocol HasMapBuilder {
  var mapBuilder: MapBuildable { get }
}

typealias RootDependency = HasAgendaBuilder & HasMapBuilder

protocol RootBuildable: Buildable {
  func build() -> LaunchRouting
}

class RootBuilder: Builder<RootDependency> {
  func build() -> LaunchRouting {
    let viewController = RootViewController()
    let interactor = RootInteractor()
    let router = RootRouter(interactor: interactor, viewController: viewController, agendaBuilder: dependency.agendaBuilder, mapBuilder: dependency.mapBuilder)
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

  private let agendaBuilder: AgendaBuildable
  private let mapBuilder: MapBuildable

  init(interactor: RootInteractable, viewController: RootViewControllable, agendaBuilder: AgendaBuildable, mapBuilder: MapBuildable) {
    self.agendaBuilder = agendaBuilder
    self.mapBuilder = mapBuilder
    super.init(interactor: interactor, viewController: viewController)
  }

  override func didLoad() {
    super.didLoad()

    let agendaRouter = agendaBuilder.build(with: interactor)
    self.agendaRouter = agendaRouter
    attachChild(agendaRouter)
    viewController.addAgenda(agendaRouter.viewControllable)

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
  func removeAgenda()

  func addMap(_ mapViewControllable: ViewControllable)
  func removeMap()
}

class RootViewController: UITabBarController {
  private var agendaViewController: UIViewController? {
    didSet { didChangeViewControllers() }
  }

  private var mapViewController: UIViewController? {
    didSet { didChangeViewControllers() }
  }

  private func didChangeViewControllers() {
    viewControllers = [agendaViewController, mapViewController].compactMap { $0 }
  }
}

extension RootViewController: RootViewControllable {
  func addAgenda(_ agendaViewControllable: ViewControllable) {
    agendaViewController = agendaViewControllable.uiviewController
    agendaViewController?.title = L10n.Agenda.title
    agendaViewController?.tabBarItem.accessibilityIdentifier = "agenda"
    agendaViewController?.tabBarItem.image = .fos_systemImage(withName: "calendar")
  }

  func removeAgenda() {
    agendaViewController = nil
  }

  func addMap(_ mapViewControllable: ViewControllable) {
    mapViewController = mapViewControllable.uiviewController
    mapViewController?.title = L10n.Map.title
    mapViewController?.tabBarItem.accessibilityIdentifier = "map"
    mapViewController?.tabBarItem.image = .fos_systemImage(withName: "map")
  }

  func removeMap() {
    mapViewController = nil
  }
}

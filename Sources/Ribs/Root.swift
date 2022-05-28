import RIBs
import UIKit

protocol HasAgendaBuilder {
  var agendaBuilder: AgendaBuildable { get }
}

typealias RootDependency = HasAgendaBuilder

protocol RootBuildable: Buildable {
  func build() -> LaunchRouting
}

class RootBuilder: Builder<RootDependency> {
  func build() -> LaunchRouting {
    let viewController = RootViewController()
    let interactor = RootInteractor()
    let router = RootRouter(interactor: interactor, viewController: viewController, agendaBuilder: dependency.agendaBuilder)
    interactor.router = router
    return router
  }
}

protocol RootRouting: Routing {
  func removeAgenda()
}

class RootRouter: LaunchRouter<RootInteractable, RootViewControllable> {
  private var agendaRouter: ViewableRouting?

  private let agendaBuilder: AgendaBuildable

  init(interactor: RootInteractable, viewController: RootViewControllable, agendaBuilder: AgendaBuildable) {
    self.agendaBuilder = agendaBuilder
    super.init(interactor: interactor, viewController: viewController)
  }

  override func didLoad() {
    super.didLoad()

    let agendaRouter = agendaBuilder.build(with: interactor)
    self.agendaRouter = agendaRouter
    attachChild(agendaRouter)
    viewController.addAgenda(agendaRouter.viewControllable)
  }
}

extension RootRouter: RootRouting {
  func removeAgenda() {
    viewController.removeAgenda()
  }
}

protocol RootInteractable: Interactable, AgendaListener {}

class RootInteractor: Interactor {
  var router: RootRouting?
}

extension RootInteractor: RootInteractable {
  func didError(_: Error) {
    router?.removeAgenda()
    // TODO: show error if needed?
  }
}

protocol RootViewControllable: ViewControllable {
  func addAgenda(_ agendaViewControllable: ViewControllable)
  func removeAgenda()
}

class RootViewController: UITabBarController {
  private weak var agendaViewController: UIViewController?
}

extension RootViewController: RootViewControllable {
  func addAgenda(_ agendaViewControllable: ViewControllable) {
    let agendaViewController = agendaViewControllable.uiviewController
    self.agendaViewController = agendaViewController
    viewControllers = [agendaViewController]
  }

  func removeAgenda() {
    viewControllers?.removeAll { viewController in
      viewController === agendaViewController
    }
  }
}

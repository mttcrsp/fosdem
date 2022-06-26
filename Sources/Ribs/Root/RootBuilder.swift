import NeedleFoundation
import RIBs
import UIKit

protocol RootBuildable: Buildable {
  func build(with component: RootComponent) -> LaunchRouting
}

class RootBuilder: SimpleComponentizedBuilder<RootComponent, LaunchRouting> {
  override func build(with component: RootComponent) -> LaunchRouting {
    let viewController = RootViewController()
    let interactor = RootInteractor(component: component, presenter: viewController)
    let router = RootRouter(component: component, interactor: interactor, viewController: viewController,agendaBuilder: component.makeAgendaBuilder(with: <#T##PersistenceServiceProtocol#>))
    interactor.router = router
    viewController.listener = interactor
    return router
  }
}

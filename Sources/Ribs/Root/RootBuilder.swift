import RIBs
import UIKit

protocol RootBuilders {
  var agendaBuilder: AgendaBuildable { get }
  var mapBuilder: MapBuildable { get }
  var moreBuilder: MoreBuildable { get }
  var scheduleBuilder: ScheduleBuildable { get }
}

protocol RootServices {
  var openService: OpenServiceProtocol { get }
}

protocol RootDependency: Dependency, RootBuilders, RootServices {}

protocol RootBuildable: Buildable {
  func build() -> LaunchRouting
}

class RootBuilder: Builder<RootDependency> {
  func build() -> LaunchRouting {
    let viewController = RootViewController()
    let interactor = RootInteractor(presenter: viewController, services: dependency)
    let router = RootRouter(builders: dependency, interactor: interactor, viewController: viewController)
    interactor.router = router
    viewController.listener = interactor
    return router
  }
}

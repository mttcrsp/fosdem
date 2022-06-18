import RIBs
import UIKit

protocol RootBuilders {
  var agendaBuilder: AgendaBuildable { get }
  var mapBuilder: MapBuildable { get }
  var moreBuilder: MoreBuildable { get }
  var scheduleBuilder: ScheduleBuildable { get }
}

protocol RootDependency: Dependency, RootBuilders {}

protocol RootBuildable: Buildable {
  func build() -> LaunchRouting
}

class RootBuilder: Builder<RootDependency> {
  func build() -> LaunchRouting {
    let viewController = RootViewController()
    let interactor = RootInteractor(presenter: viewController)
    let router = RootRouter(builders: dependency, interactor: interactor, viewController: viewController)
    interactor.router = router
    return router
  }
}

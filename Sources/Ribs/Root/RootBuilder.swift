import RIBs
import UIKit

typealias RootBuilders = HasAgendaBuilder & HasMapBuilder & HasMoreBuilder & HasScheduleBuilder
typealias RootDependency = RootBuilders

protocol RootBuildable: Buildable {
  func build() -> LaunchRouting
}

class RootBuilder: Builder<RootDependency> {
  func build() -> LaunchRouting {
    let viewController = RootViewController()
    let interactor = RootInteractor()
    let router = RootRouter(builders: dependency, interactor: interactor, viewController: viewController)
    interactor.router = router
    return router
  }
}

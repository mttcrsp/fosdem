import RIBs
import UIKit

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

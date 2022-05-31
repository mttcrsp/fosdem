import RIBs

typealias MoreBuilders = HasYearsBuilder & HasVideosBuilder
typealias MoreServices = HasAcknowledgementsService & HasInfoService & HasOpenService & HasTimeService & HasYearsService
typealias MoreDependency = MoreBuilders & MoreServices

protocol MoreBuildable: Buildable {
  func build() -> MoreRouting
}

final class MoreBuilder: Builder<MoreDependency>, MoreBuildable {
  func build() -> MoreRouting {
    let viewController = MoreRootViewController()
    let interactor = MoreInteractor(presenter: viewController, services: dependency)
    let router = MoreRouter(builders: dependency, interactor: interactor, viewController: viewController)
    viewController.listener = interactor
    interactor.router = router
    return router
  }
}

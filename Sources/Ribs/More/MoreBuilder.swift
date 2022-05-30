import RIBs

typealias MoreDependency = HasAcknowledgementsService
  & HasInfoService
  & HasOpenService
  & HasTimeService
  & HasYearsBuilder
  & HasYearsService
  & HasVideosBuilder

protocol MoreBuildable: Buildable {
  func build() -> MoreRouting
}

final class MoreBuilder: Builder<MoreDependency>, MoreBuildable {
  func build() -> MoreRouting {
    let viewController = MoreContainerViewController()
    let interactor = MoreInteractor(presenter: viewController, dependency: dependency)
    let router = MoreRouter(interactor: interactor, viewController: viewController, videosBuilder: dependency.videosBuilder, yearsBuilder: dependency.yearsBuilder)
    viewController.listener = interactor
    interactor.router = router
    return router
  }
}

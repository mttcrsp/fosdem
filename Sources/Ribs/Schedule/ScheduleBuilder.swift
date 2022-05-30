import RIBs

typealias ScheduleDependency = HasEventBuilder
  & HasFavoritesService
  & HasPersistenceService
  & HasSearchBuilder
  & HasTracksService
  & HasYearsService

protocol ScheduleBuildable: Buildable {
  func build() -> ScheduleRouting
}

final class ScheduleBuilder: Builder<ScheduleDependency>, ScheduleBuildable {
  func build() -> ScheduleRouting {
    let viewController = ScheduleViewController()
    let interactor = ScheduleInteractor(presenter: viewController, dependency: dependency)
    let router = ScheduleRouter(
      interactor: interactor,
      viewController: viewController,
      eventBuilder: dependency.eventBuilder,
      searchBuilder: dependency.searchBuilder
    )
    viewController.listener = interactor
    interactor.router = router
    return router
  }
}

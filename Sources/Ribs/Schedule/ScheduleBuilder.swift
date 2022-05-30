import RIBs

typealias ScheduleDependency = HasEventBuilder
  & HasFavoritesService
  & HasPersistenceService
  & HasSearchBuilder
  & HasTrackBuilder
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
      trackBuilder: dependency.trackBuilder,
      searchBuilder: dependency.searchBuilder
    )
    viewController.listener = interactor
    interactor.router = router
    return router
  }
}

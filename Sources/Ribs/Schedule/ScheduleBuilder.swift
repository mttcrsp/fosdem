import RIBs

typealias ScheduleBuilders = HasEventBuilder & HasSearchBuilder & HasTrackBuilder
typealias ScheduleServices = HasFavoritesService & HasPersistenceService & HasTracksService & HasYearsService
typealias ScheduleDependency = ScheduleBuilders & ScheduleServices

protocol ScheduleBuildable: Buildable {
  func build() -> ScheduleRouting
}

final class ScheduleBuilder: Builder<ScheduleDependency>, ScheduleBuildable {
  func build() -> ScheduleRouting {
    let viewController = ScheduleViewController()
    let interactor = ScheduleInteractor(presenter: viewController, services: dependency)
    let router = ScheduleRouter(builders: dependency, interactor: interactor, viewController: viewController)
    viewController.listener = interactor
    interactor.router = router
    return router
  }
}

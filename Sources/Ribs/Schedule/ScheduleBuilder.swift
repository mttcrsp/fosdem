import RIBs

protocol ScheduleBuilders {
  var eventBuilder: EventBuildable { get }
  var searchBuilder: SearchBuildable { get }
  var trackBuilder: TrackBuildable { get }
}

protocol ScheduleServices {
  var favoritesService: FavoritesServiceProtocol { get }
  var persistenceService: PersistenceServiceProtocol { get }
  var tracksService: TracksServiceProtocol { get }
  var yearsService: YearsServiceProtocol { get }
}

protocol ScheduleDependency: Dependency, ScheduleBuilders, ScheduleServices {}

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

import NeedleFoundation
import RIBs

protocol ScheduleDependency: NeedleFoundation.Dependency {
  var favoritesService: FavoritesServiceProtocol { get }
  var yearsService: YearsServiceProtocol { get }
}

final class ScheduleComponent: NeedleFoundation.Component<ScheduleDependency> {
  let persistenceService: PersistenceServiceProtocol

  init(parent: Scope, persistenceService: PersistenceServiceProtocol) {
    self.persistenceService = persistenceService
    super.init(parent: parent)
  }

  var tracksService: TracksServiceProtocol {
    shared { TracksService(favoritesService: dependency.favoritesService, persistenceService: persistenceService) }
  }

  func buildEventRouter(withArguments arguments: EventArguments) -> ViewableRouting {
    EventBuilder(componentBuilder: { EventComponent(parent: self) })
      .finalStageBuild(withDynamicDependency: arguments)
  }

  func buildSearchRouter(withArguments arguments: SearchArguments, listener: SearchListener) -> ViewableRouting {
    SearchBuilder(componentBuilder: { SearchComponent(parent: self) })
      .finalStageBuild(withDynamicDependency: (arguments, listener))
  }

  func buildTrackRouter(withArguments arguments: TrackArguments, listener: TrackListener) -> ViewableRouting {
    TrackBuilder(componentBuilder: { TrackComponent(parent: self) })
      .finalStageBuild(withDynamicDependency: (arguments, listener))
  }
}

protocol ScheduleBuildable: Buildable {
  func build() -> ViewableRouting
}

final class ScheduleBuilder: SimpleComponentizedBuilder<ScheduleComponent, ViewableRouting>, ScheduleBuildable {
  override func build(with component: ScheduleComponent) -> ViewableRouting {
    let viewController = ScheduleViewController()
    let interactor = ScheduleInteractor(component: component, presenter: viewController)
    let router = ScheduleRouter(component: component, interactor: interactor, viewController: viewController)
    viewController.listener = interactor
    interactor.router = router
    return router
  }
}

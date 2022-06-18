import NeedleFoundation
import RIBs

protocol ScheduleDependency: NeedleFoundation.Dependency {
  var favoritesService: FavoritesServiceProtocol { get }
  var yearsService: YearsServiceProtocol { get }
}

final class ScheduleComponent: NeedleFoundation.Component<ScheduleDependency> {
  var eventBuilder: EventBuildable { fatalError() }
  var searchBuilder: SearchBuildable { fatalError() }
  var trackBuilder: TrackBuildable { fatalError() }

  let persistenceService: PersistenceServiceProtocol

  init(parent: Scope, persistenceService: PersistenceServiceProtocol) {
    self.persistenceService = persistenceService
    super.init(parent: parent)
  }
}

extension ScheduleComponent {
  var tracksService: TracksServiceProtocol {
    shared { TracksService(favoritesService: dependency.favoritesService, persistenceService: persistenceService) }
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

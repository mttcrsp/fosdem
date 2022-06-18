import NeedleFoundation
import RIBs

struct TrackArguments {
  let track: Track
}

protocol TrackDependency: NeedleFoundation.Dependency {
  var favoritesService: FavoritesServiceProtocol { get }
  var persistenceService: PersistenceServiceProtocol { get }
}

final class TrackComponent: NeedleFoundation.Component<TrackDependency> {
  var eventBuilder: EventBuildable { fatalError() }
}

protocol TrackBuildable: Buildable {
  func finalStageBuild(withDynamicDependency: (TrackArguments, TrackListener)) -> ViewableRouting
}

final class TrackBuilder: MultiStageComponentizedBuilder<TrackComponent, ViewableRouting, (TrackArguments, TrackListener)>, TrackBuildable {
  override func finalStageBuild(with component: TrackComponent, _ dynamicDependency: (arguments: TrackArguments, listener: TrackListener)) -> ViewableRouting {
    let viewController = TrackViewController()
    let interactor = TrackInteractor(arguments: dynamicDependency.arguments, component: component, presenter: viewController)
    let router = TrackRouter(component: component, interactor: interactor, viewController: viewController)
    interactor.listener = dynamicDependency.listener
    interactor.router = router
    viewController.listener = interactor
    return router
  }
}

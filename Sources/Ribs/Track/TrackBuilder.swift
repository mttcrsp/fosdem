import RIBs

struct TrackArguments {
  let track: Track
}

protocol TrackBuilders {
  var eventBuilder: EventBuildable { get }
}

protocol TrackServices {
  var favoritesService: FavoritesServiceProtocol { get }
  var persistenceService: PersistenceServiceProtocol { get }
}

protocol TrackDependency: Dependency, TrackBuilders, TrackServices {}

protocol TrackBuildable: Buildable {
  func build(withListener listener: TrackListener, arguments: TrackArguments) -> TrackRouting
}

final class TrackBuilder: Builder<TrackDependency>, TrackBuildable {
  func build(withListener listener: TrackListener, arguments: TrackArguments) -> TrackRouting {
    let viewController = TrackViewController()
    let interactor = TrackInteractor(arguments: arguments, presenter: viewController, services: dependency)
    let router = TrackRouter(builders: dependency, interactor: interactor, viewController: viewController)
    interactor.listener = listener
    return router
  }
}

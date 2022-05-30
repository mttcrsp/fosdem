import RIBs

typealias TrackDependency = HasEventBuilder
  & HasFavoritesService
  & HasPersistenceService

struct TrackArguments {
  let track: Track
}

protocol TrackBuildable: Buildable {
  func build(withListener listener: TrackListener, arguments: TrackArguments) -> TrackRouting
}

final class TrackBuilder: Builder<TrackDependency>, TrackBuildable {
  func build(withListener listener: TrackListener, arguments: TrackArguments) -> TrackRouting {
    let viewController = TrackViewController()
    let interactor = TrackInteractor(arguments: arguments, dependency: dependency, presenter: viewController)
    let router = TrackRouter(interactor: interactor, viewController: viewController, eventBuilder: dependency.eventBuilder)
    interactor.listener = listener
    return router
  }
}

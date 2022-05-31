import RIBs

typealias TrackServices = HasFavoritesService & HasPersistenceService
typealias TrackBuilders = HasEventBuilder
typealias TrackDependency = TrackBuilders & TrackServices

struct TrackArguments {
  let track: Track
}

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

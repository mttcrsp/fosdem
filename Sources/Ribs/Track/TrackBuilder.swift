import RIBs

protocol TrackDependency: Dependency {}

protocol TrackBuildable: Buildable {
  func build(withListener listener: TrackListener) -> TrackRouting
}

final class TrackBuilder: Builder<TrackDependency>, TrackBuildable {
  func build(withListener listener: TrackListener) -> TrackRouting {
    let viewController = TrackViewController()
    let interactor = TrackInteractor(presenter: viewController)
    let router = TrackRouter(interactor: interactor, viewController: viewController)
    interactor.listener = listener
    return router
  }
}

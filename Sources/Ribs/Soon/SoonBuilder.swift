import RIBs

typealias SoonDependency = HasEventBuilder
  & HasFavoritesService
  & HasSoonService

protocol SoonBuildable: Buildable {
  func build(withListener listener: SoonListener) -> SoonRouting
}

final class SoonBuilder: Builder<SoonDependency>, SoonBuildable {
  func build(withListener listener: SoonListener) -> SoonRouting {
    let viewController = SoonViewController()
    let interactor = SoonInteractor(dependency: dependency, presenter: viewController)
    let router = SoonRouter(interactor: interactor, viewController: viewController, eventBuilder: dependency.eventBuilder)
    interactor.listener = listener
    interactor.router = router
    viewController.listener = interactor
    return router
  }
}

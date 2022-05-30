import RIBs

typealias SearchDependency = HasFavoritesService & HasPersistenceService

protocol SearchBuildable: Buildable {
  func build(withListener listener: SearchListener) -> ViewableRouting
}

final class SearchBuilder: Builder<SearchDependency>, SearchBuildable {
  func build(withListener listener: SearchListener) -> ViewableRouting {
    let viewController = SearchViewController()
    let interactor = SearchInteractor(presenter: viewController, dependency: dependency)
    let router = ViewableRouter(interactor: interactor, viewController: viewController)
    interactor.listener = listener
    viewController.listener = interactor
    return router
  }
}

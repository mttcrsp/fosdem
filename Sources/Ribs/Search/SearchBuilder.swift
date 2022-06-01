import RIBs

protocol SearchServices {
  var favoritesService: FavoritesServiceProtocol { get }
  var persistenceService: PersistenceServiceProtocol { get }
}

protocol SearchDependency: Dependency, SearchServices {}

protocol SearchBuildable: Buildable {
  func build(withListener listener: SearchListener) -> ViewableRouting
}

final class SearchBuilder: Builder<SearchDependency>, SearchBuildable {
  func build(withListener listener: SearchListener) -> ViewableRouting {
    let viewController = SearchViewController()
    let interactor = SearchInteractor(presenter: viewController, services: dependency)
    let router = ViewableRouter(interactor: interactor, viewController: viewController)
    interactor.listener = listener
    viewController.listener = interactor
    return router
  }
}

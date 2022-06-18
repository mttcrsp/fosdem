import RIBs

struct SearchArguments {
  let persistenceService: PersistenceServiceProtocol
  let favoritesService: FavoritesServiceProtocol?
}

protocol SearchDependency: Dependency {}

protocol SearchBuildable: Buildable {
  func build(withArguments arguments: SearchArguments, listener: SearchListener) -> ViewableRouting
}

final class SearchBuilder: Builder<SearchDependency>, SearchBuildable {
  func build(withArguments arguments: SearchArguments, listener: SearchListener) -> ViewableRouting {
    let viewController = SearchViewController()
    let interactor = SearchInteractor(arguments: arguments, presenter: viewController)
    let router = ViewableRouter(interactor: interactor, viewController: viewController)
    interactor.listener = listener
    viewController.listener = interactor
    return router
  }
}

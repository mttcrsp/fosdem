import NeedleFoundation
import RIBs

struct SearchArguments {
  let persistenceService: PersistenceServiceProtocol
  let allowsFavoriting: Bool

  init(persistenceService: PersistenceServiceProtocol, allowsFavoriting: Bool = true) {
    self.persistenceService = persistenceService
    self.allowsFavoriting = allowsFavoriting
  }
}

protocol SearchDependency: NeedleFoundation.Dependency {
  var favoritesService: FavoritesServiceProtocol { get }
}

final class SearchComponent: NeedleFoundation.Component<SearchDependency> {}

protocol SearchBuildable: Buildable {
  func finalStageBuild(withDynamicDependency dynamicDependency: (SearchArguments, SearchListener)) -> ViewableRouting
}

final class SearchBuilder: MultiStageComponentizedBuilder<SearchComponent, ViewableRouting, (SearchArguments, SearchListener)>, SearchBuildable {
  override func finalStageBuild(with component: SearchComponent, _ dynamicDependency: (arguments: SearchArguments, listener: SearchListener)) -> ViewableRouting {
    let viewController = SearchViewController()
    let interactor = SearchInteractor(arguments: dynamicDependency.arguments, component: component, presenter: viewController)
    let router = ViewableRouter(interactor: interactor, viewController: viewController)
    interactor.listener = dynamicDependency.listener
    viewController.listener = interactor
    return router
  }
}

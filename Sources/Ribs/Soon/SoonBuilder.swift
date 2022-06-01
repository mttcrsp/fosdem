import RIBs

protocol SoonBuilders {
  var eventBuilder: EventBuildable { get }
}

protocol SoonServices {
  var favoritesService: FavoritesServiceProtocol { get }
  var soonService: SoonServiceProtocol { get }
}

protocol SoonDependency: Dependency, SoonBuilders, SoonServices {}

protocol SoonBuildable: Buildable {
  func build(withListener listener: SoonListener) -> SoonRouting
}

final class SoonBuilder: Builder<SoonDependency>, SoonBuildable {
  func build(withListener listener: SoonListener) -> SoonRouting {
    let viewController = SoonViewController()
    let interactor = SoonInteractor(services: dependency, presenter: viewController)
    let router = SoonRouter(builders: dependency, interactor: interactor, viewController: viewController)
    interactor.listener = listener
    interactor.router = router
    viewController.listener = interactor
    return router
  }
}

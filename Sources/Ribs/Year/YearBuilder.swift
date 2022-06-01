import RIBs

protocol YearBuilders {
  var eventBuilder: EventBuildable { get }
  var searchBuilder: SearchBuildable { get }
}

protocol YearServices {
  var yearsService: YearsServiceProtocol { get }
}

protocol YearDependency: Dependency, YearBuilders, YearServices {}

struct YearArguments {
  let year: Year
}

protocol YearBuildable: Buildable {
  func build(with arguments: YearArguments, listener: YearListener) -> YearRouting
}

final class YearBuilder: Builder<YearDependency>, YearBuildable {
  func build(with arguments: YearArguments, listener: YearListener) -> YearRouting {
    let viewController = YearViewController()
    let interactor = YearInteractor(arguments: arguments, presenter: viewController, services: dependency)
    let router = YearRouter(builders: dependency, interactor: interactor, viewController: viewController)
    interactor.listener = listener
    interactor.router = router
    viewController.listener = interactor
    return router
  }
}

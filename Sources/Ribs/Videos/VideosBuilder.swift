import RIBs

typealias VideosDependency = HasEventBuilder & HasPlaybackService & HasVideosService

protocol VideosListener: AnyObject {
  func videosDidError(_ error: Error)
  func videosDidDismiss()
}

protocol VideosBuildable: Buildable {
  func build(with listener: VideosListener) -> VideosRouting
}

final class VideosBuilder: Builder<VideosDependency>, VideosBuildable {
  func build(with listener: VideosListener) -> VideosRouting {
    let viewController = VideosViewController()
    let interactor = VideosInteractor(presenter: viewController, dependency: dependency)
    let router = VideosRouter(interactor: interactor, viewController: viewController, eventBuilder: dependency.eventBuilder)
    interactor.listener = listener
    interactor.router = router
    viewController.listener = interactor
    return router
  }
}

import RIBs

protocol VideosBuilders {
  var eventBuilder: EventBuildable { get }
}

protocol VideosServices {
  var playbackService: PlaybackServiceProtocol { get }
  var videosService: VideosServiceProtocol { get }
}

protocol VideosDependency: Dependency, VideosBuilders, VideosServices {}

protocol VideosListener: AnyObject {
  func videosDidError(_ error: Error)
  func videosDidDismiss()
}

protocol VideosBuildable: Buildable {
  func build(withListener listener: VideosListener) -> VideosRouting
}

final class VideosBuilder: Builder<VideosDependency>, VideosBuildable {
  func build(withListener listener: VideosListener) -> VideosRouting {
    let viewController = VideosViewController()
    let interactor = VideosInteractor(presenter: viewController, services: dependency)
    let router = VideosRouter(builders: dependency, interactor: interactor, viewController: viewController)
    interactor.listener = listener
    interactor.router = router
    viewController.listener = interactor
    return router
  }
}

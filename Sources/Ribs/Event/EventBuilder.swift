import RIBs

struct EventArguments {
  let event: Event
  let allowsFavoriting: Bool

  init(event: Event, allowsFavoriting: Bool = true) {
    self.event = event
    self.allowsFavoriting = allowsFavoriting
  }
}

typealias EventDependency = HasAudioSession
  & HasFavoritesService
  & HasNotificationCenter
  & HasPlaybackService
  & HasPlayer
  & HasTimeService

protocol EventBuildable {
  func build(with arguments: EventArguments) -> ViewableRouting
}

final class EventBuilder: Builder<EventDependency>, EventBuildable {
  func build(with arguments: EventArguments) -> ViewableRouting {
    let viewController = EventContainerViewController(event: arguments.event)
    let interactor = EventInteractor(arguments: arguments, dependency: dependency, presenter: viewController)
    let router = ViewableRouter(interactor: interactor, viewController: viewController)
    viewController.listener = interactor
    return router
  }
}

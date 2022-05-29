import RIBs

protocol RootRouting: Routing {
  func removeAgenda()
  func removeMap()
}

class RootInteractor: Interactor {
  var router: RootRouting?
}

extension RootInteractor: RootInteractable {
  func agendaDidError(_: Error) {
    router?.removeAgenda()
    // TODO: show error if needed?
  }

  func mapDidError(_: Error) {
    router?.removeMap()
    // TODO: show error if needed?
  }
}

import Foundation
import RIBs

protocol RootRouting: Routing {
  func attach(withDynamicBuildDependency persistenceService: PersistenceServiceProtocol)
  func removeAgenda()
  func removeMap()
}

protocol RootPresentable: Presentable {
  func showError()
  func showFailure()
  func showWelcome(for year: Year)
}

class RootInteractor: PresentableInteractor<RootPresentable> {
  var router: RootRouting?

  private let component: RootComponent

  init(component: RootComponent, presenter: RootPresentable) {
    self.component = component
    super.init(presenter: presenter)
  }

  override func didBecomeActive() {
    super.didBecomeActive()

    do {
      let launchService = LaunchService(fosdemYear: YearsService.current)
      try launchService.detectStatus()

      if launchService.didLaunchAfterFosdemYearChange {
        let favoritesService = FavoritesService()
        favoritesService.removeAllTracksAndEvents()
      }

      // Remove the database after each update as the new database might contain
      // updates even if the year did not change.
      let preloadService = try PreloadService()
      if launchService.didLaunchAfterUpdate {
        try preloadService.removeDatabase()
      }

      // In the 2020 release, installs and updates where not being recorded. This
      // means that users updating from 2020 to new version will be registered as
      // new installs. The database also needs to be removed for those users too.
      if launchService.didLaunchAfterInstall {
        do {
          try preloadService.removeDatabase()
        } catch {
          if let error = error as? CocoaError, error.code == .fileNoSuchFile {
            // Do nothing
          } else {
            throw error
          }
        }
      }

      try preloadService.preloadDatabaseIfNeeded()

      let persistenceService = try PersistenceService(path: preloadService.databasePath, migrations: .allMigrations)
      router?.attach(withDynamicBuildDependency: persistenceService)

      if launchService.didLaunchAfterInstall {
        let year = type(of: component.yearsService).current
        presenter.showWelcome(for: year)
      }
    } catch {
      presenter.showFailure()
    }
  }
}

extension RootInteractor: RootInteractable {
  func agendaDidError(_: Error) {
    router?.removeAgenda()
    presenter.showError()
  }

  func mapDidError(_: Error) {
    router?.removeMap()
  }
}

extension RootInteractor: RootPresentableListener {
  func openAppStore() {
    if let url = URL.fosdemAppStore {
      component.openService.open(url, completion: nil)
    }
  }
}

private extension URL {
  static var fosdemAppStore: URL? {
    URL(string: "https://itunes.apple.com/it/app/id1513719757")
  }
}

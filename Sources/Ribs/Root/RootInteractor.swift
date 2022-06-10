import RIBs
import Foundation

protocol RootRouting: Routing {
  func removeAgenda()
  func removeMap()
}

class RootInteractor: Interactor {
  var router: RootRouting?
  
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
      
    } catch {
      
    }
    
  }
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

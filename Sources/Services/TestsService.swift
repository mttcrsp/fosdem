#if DEBUG
import UIKit

final class TestsService {
  private let environment: [String: String]
  private let favoritesService: FavoritesService

  init(favoritesService: FavoritesService, environment: [String: String] = ProcessInfo.processInfo.environment) {
    self.favoritesService = favoritesService
    self.environment = environment
  }

  func configureEnvironment() {
    DispatchQueue.main.async {
      UIApplication.shared.keyWindow?.layer.speed = 100
    }

    if environment["RESET_FAVORITES"] != nil {
      for identifier in favoritesService.eventsIdentifiers {
        favoritesService.removeEvent(withIdentifier: identifier)
      }

      for identifier in favoritesService.tracksIdentifiers {
        favoritesService.removeTrack(withIdentifier: identifier)
      }
    }
  }
}
#endif

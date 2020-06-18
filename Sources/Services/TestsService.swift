#if DEBUG
import UIKit

final class TestsService {
  private let formatter = ISO8601DateFormatter()

  private var timer: Timer?

  private let environment: [String: String]
  private let debugService: DebugService
  private let favoritesService: FavoritesService

  init(favoritesService: FavoritesService, debugService: DebugService, environment: [String: String] = ProcessInfo.processInfo.environment) {
    self.favoritesService = favoritesService
    self.debugService = debugService
    self.environment = environment
  }

  var liveTimerInterval: TimeInterval? {
    if let string = environment["LIVE_INTERVAL"] {
      return TimeInterval(string)
    } else {
      return nil
    }
  }

  func configureEnvironment() {
    DispatchQueue.main.async {
      UIApplication.shared.keyWindow?.layer.speed = 100
    }

    if environment["RESET_DEFAULTS"] != nil, let name = Bundle.main.bundleIdentifier {
      UserDefaults.standard.removePersistentDomain(forName: name)
    }

    if let tracks = environment["FAVORITE_EVENTS"] {
      for identifier in favoritesService.eventsIdentifiers {
        favoritesService.removeEvent(withIdentifier: identifier)
      }

      let identifiers = tracks.components(separatedBy: ",")
      for identifier in identifiers {
        if let identifier = Int(identifier) {
          favoritesService.addEvent(withIdentifier: identifier)
        }
      }
    }

    if let string = environment["SOON_DATE"] {
      if let date = formatter.date(from: string) {
        debugService.override(date)
      }
    }

    if let string = environment["LIVE_DATES"] {
      let components = string.components(separatedBy: ",")
      if components.count == 2,
        let date1 = formatter.date(from: components[0]),
        let date2 = formatter.date(from: components[1]) {
        var flag = true
        timer = .scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
          self?.debugService.override(flag ? date1 : date2)
          flag.toggle()
        }
      }
    }
  }
}
#endif

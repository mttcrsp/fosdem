#if DEBUG
import UIKit

final class TestsService {
  private var datesTimer: Timer?
  private var videoTimer: Timer?

  private let debugService: DebugService
  private let favoritesService: FavoritesService
  private let persistenceService: PersistenceService

  init(persistenceService: PersistenceService, favoritesService: FavoritesService, debugService: DebugService) {
    self.persistenceService = persistenceService
    self.favoritesService = favoritesService
    self.debugService = debugService
  }

  private var environment: [String: String] {
    ProcessInfo.processInfo.environment
  }

  var liveTimerInterval: TimeInterval? {
    if let string = environment["LIVE_INTERVAL"] {
      return TimeInterval(string)
    } else {
      return nil
    }
  }

  var shouldUpdateSchedule: Bool {
    environment["ENABLE_SCHEDULE_UPDATES"] != nil
  }

  var shouldDiplayOnboarding: Bool {
    environment["ENABLE_ONBOARDING"] != nil
  }

  func configureEnvironment() {
    if ProcessInfo.processInfo.isRunningUITests {
      DispatchQueue.main.async {
        UIApplication.shared.keyWindow?.layer.speed = 100
      }
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

    if let tracks = environment["FAVORITE_TRACKS"] {
      for identifier in favoritesService.tracksIdentifiers {
        favoritesService.removeTrack(withIdentifier: identifier)
      }

      let identifiers = tracks.components(separatedBy: ",")
      for identifier in identifiers {
        favoritesService.addTrack(withIdentifier: identifier)
      }
    }

    if let string = environment["SOON_DATE"] {
      if let value = Double(string) {
        debugService.override(Date(timeIntervalSince1970: value))
      }
    }

    if let string = environment["LIVE_DATES"] {
      let components = string.components(separatedBy: ",")
      if components.count == 2, let value1 = Double(components[0]), let value2 = Double(components[1]) {
        let date1 = Date(timeIntervalSince1970: value1)
        let date2 = Date(timeIntervalSince1970: value2)

        var flag = true
        datesTimer = .scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
          self?.debugService.override(flag ? date1 : date2)
          flag.toggle()
        }
      }
    }

    if let base64 = environment["VIDEO"], let data = Data(base64Encoded: base64) {
      // HACK: Overriding the video URL every second ensures that the change
      // will not be overridden by schedule updates.
      videoTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
        do {
          let directory = FileManager.default.temporaryDirectory
          let url = directory.appendingPathComponent("test.mp4")
          try data.write(to: url)

          let links = [Link(name: "test", url: url)]
          let write = UpdateLinksForEvent(eventID: 11423, links: links)
          try self?.persistenceService.performWriteSync(write)
        } catch {
          assertionFailure(error.localizedDescription)
        }
      }
    }
  }
}
#endif

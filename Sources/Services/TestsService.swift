#if ENABLE_UITUNNEL
import SBTUITestTunnelServer

private protocol TestsServiceCommand {
  static var name: String { get }
  static func perform(with services: Services, object: NSObject?)
}

final class TestsService {
  private let commands: [TestsServiceCommand.Type] = [
    EnableOnboarding.self,
    EnableScheduleUpdates.self,
    OverrideDate.self,
    OverrideEventVideo.self,
    ResetDefaults.self,
    SetFavoritesEvents.self,
    SetFavoritesTracks.self,
    SetLiveUpdatesInterval.self,
    ToggleDatesOverride.self,
  ]

  private let services: Services

  init(services: Services) {
    self.services = services
  }

  func start() {
    SBTUITestTunnelServer.takeOff()
  }

  func registerCustomCommands() {
    for command in commands {
      SBTUITestTunnelServer.registerCustomCommandNamed(command.name) { object in
        DispatchQueue.main.sync {
          command.perform(with: self.services, object: object)
        }
        return nil
      }
    }
  }

  func speedUpAnimations(in window: UIWindow) {
    window.layer.speed = 100
  }
}

private struct EnableOnboarding: TestsServiceCommand {
  static let name = "ENABLE_ONBOARDING"
  static func perform(with services: Services, object _: NSObject?) {
    services.launchService.markAsLaunched()
  }
}

private struct ResetDefaults: TestsServiceCommand {
  static let name = "RESET_DEFAULTS"
  static func perform(with _: Services, object _: NSObject?) {
    if let name = Bundle.main.bundleIdentifier {
      UserDefaults.standard.removePersistentDomain(forName: name)
    } else {
      assertionFailure("Unable to determine main bundle identifier")
    }
  }
}

private struct SetFavoritesEvents: TestsServiceCommand {
  static let name = "SET_FAVORITE_EVENTS"
  static func perform(with services: Services, object: NSObject?) {
    if let identifiers = object as? [Int] {
      services.favoritesService.setEventsIdentifiers(Set(identifiers))
    } else {
      assertionFailure("Unexpected input to SET_FAVORITE_EVENTS command \(object as Any)")
    }
  }
}

private struct SetFavoritesTracks: TestsServiceCommand {
  static let name = "SET_FAVORITE_TRACKS"
  static func perform(with services: Services, object: NSObject?) {
    if let identifiers = object as? [String] {
      services.favoritesService.setTracksIdentifiers(Set(identifiers))
    } else {
      assertionFailure("Unexpected input to SET_FAVORITE_TRACKS command \(object as Any)")
    }
  }
}

private struct OverrideDate: TestsServiceCommand {
  static let name = "OVERRIDE_DATE" // SOON_DATE
  static func perform(with services: Services, object: NSObject?) {
    if let value = object as? Double {
      services.debugService.override(Date(timeIntervalSince1970: value))
    } else {
      assertionFailure("Unexpected input to SOON_DATE command \(object as Any)")
    }
  }
}

private struct ToggleDatesOverride: TestsServiceCommand {
  private static var timer: Timer?

  static let name = "TOGGLE_DATES_OVERRIDE"
  static func perform(with services: Services, object: NSObject?) {
    guard let string = object as? String else {
      return assertionFailure("Unexpected input to TOGGLE_DATES_OVERRIDE command \(object as Any)")
    }

    let components = string.components(separatedBy: ",")
    guard components.count == 2, let value1 = Double(components[0]), let value2 = Double(components[1]) else {
      return assertionFailure("Unexpected input to TOGGLE_DATES_OVERRIDE command \(object as Any)")
    }

    let date1 = Date(timeIntervalSince1970: value1)
    let date2 = Date(timeIntervalSince1970: value2)
    var flag = true
    timer = .scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
      services.debugService.override(flag ? date1 : date2)
      flag.toggle()
    }
  }
}

private struct EnableScheduleUpdates: TestsServiceCommand {
  static let name = "ENABLE_SCHEDULE_UPDATES"
  static func perform(with services: Services, object: NSObject?) {
    if object != nil {
      services.scheduleService = nil
    } else {
      assertionFailure("Unexpected input to ENABLE_SCHEDULE_UPDATES command \(object as Any)")
    }
  }
}

private struct SetLiveUpdatesInterval: TestsServiceCommand {
  static let name = "SET_LIVE_UPDATES_INTERVAL" // LIVE_INTERVAL
  static func perform(with services: Services, object: NSObject?) {
    if let timeInterval = object as? TimeInterval {
      services.liveService = LiveService(timeInterval: timeInterval)
    } else {
      assertionFailure("Unexpected input to LIVE_INTERVAL command \(object as Any)")
    }
  }
}

private struct OverrideEventVideo: TestsServiceCommand {
  static let name = "OVERRIDE_EVENT_VIDEO" // VIDEO
  static func perform(with services: Services, object: NSObject?) {
    guard let video = object as? Data else {
      return assertionFailure("Unexpected input to LIVE_INTERVAL command \(object as Any)")
    }

    do {
      let directory = FileManager.default.temporaryDirectory
      let url = directory.appendingPathComponent("test.mp4")
      try video.write(to: url)

      let links = [Link(name: "test", url: url)]
      let write = UpdateLinksForEvent(eventID: 11717, links: links)
      try services.persistenceService.performWriteSync(write)
    } catch {
      assertionFailure(error.localizedDescription)
    }
  }
}

private extension FavoritesServiceProtocol {
  func setTracksIdentifiers(_ newTracksIdentifiers: Set<String>) {
    for identifier in tracksIdentifiers {
      removeTrack(withIdentifier: identifier)
    }

    for identifier in newTracksIdentifiers {
      addTrack(withIdentifier: identifier)
    }
  }

  func setEventsIdentifiers(_ newEventsIdentifiers: Set<Int>) {
    for identifier in eventsIdentifiers {
      removeEvent(withIdentifier: identifier)
    }

    for identifier in newEventsIdentifiers {
      addEvent(withIdentifier: identifier)
    }
  }
}
#endif

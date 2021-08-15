#if DEBUG
import UIKit

final class TestsService {
  private let preInitCommands: [PreInitCommand.Type] = [
    ResetDefaults.self,
    PreventOnboarding.self,
    SpeedUpAnimations.self,
  ]

  private let postInitCommands: [PostInitCommand.Type] = [
    OverrideDate.self,
    OverrideDates.self,
    OverrideTimeServiceInterval.self,
    OverrideVideo.self,
    PreventScheduleUpdates.self,
    SetFavoriteEvents.self,
    SetFavoriteTracks.self,
  ]

  private let environment: [String: String]

  init(environment: [String: String] = ProcessInfo.processInfo.environment) {
    self.environment = environment
  }

  func runPreInitializationTestCommands() {
    for command in preInitCommands {
      command.perform(with: environment)
    }
  }

  func runPostInitializationTestCommands(with services: Services) {
    for command in postInitCommands {
      command.perform(with: services, environment: environment)
    }
  }
}

private protocol PreInitCommand {
  static func perform(with environment: [String: String])
}

private protocol PostInitCommand {
  static func perform(with services: Services, environment: [String: String])
}

private struct ResetDefaults: PreInitCommand {
  static func perform(with environment: [String: String]) {
    guard let name = Bundle.main.bundleIdentifier, environment["RESET_DEFAULTS"] != nil else { return }
    let defaults = UserDefaults.standard
    defaults.removePersistentDomain(forName: name)
  }
}

private struct PreventOnboarding: PreInitCommand {
  static func perform(with environment: [String: String]) {
    guard environment["ENABLE_ONBOARDING"] == nil else { return }
    let defaults = UserDefaults.standard
    defaults.set(YearsService.current, forKey: LaunchService.latestFosdemYearKey)
    defaults.set(Bundle.main.bundleShortVersion, forKey: LaunchService.latestBundleShortVersionKey)
  }
}

private struct SpeedUpAnimations: PreInitCommand {
  static func perform(with _: [String: String]) {
    for window in UIApplication.shared.windows {
      window.layer.speed = 100
    }
  }
}

private struct PreventScheduleUpdates: PostInitCommand {
  static func perform(with services: Services, environment: [String: String]) {
    guard environment["ENABLE_SCHEDULE_UPDATES"] == nil else { return }
    services.scheduleService = nil
  }
}

private struct SetFavoriteEvents: PostInitCommand {
  static func perform(with services: Services, environment: [String: String]) {
    guard let value = environment["SET_FAVORITE_EVENTS"] else { return }
    let identifiers = Set(value.components(separatedBy: ",").compactMap(Int.init))
    services.favoritesService.setEventsIdentifiers(identifiers)
  }
}

private struct SetFavoriteTracks: PostInitCommand {
  static func perform(with services: Services, environment: [String: String]) {
    guard let value = environment["SET_FAVORITE_TRACKS"] else { return }
    let identifiers = Set(value.components(separatedBy: ","))
    services.favoritesService.setTracksIdentifiers(identifiers)
  }
}

private struct OverrideTimeServiceInterval: PostInitCommand {
  static func perform(with services: Services, environment: [String: String]) {
    guard let value = environment["OVERRIDE_TIME_SERVICE_INTERVAL"], let interval = TimeInterval(value) else { return }
    services.timeService = TimeService(timeInterval: interval)
  }
}

private struct OverrideDate: PostInitCommand {
  static func perform(with services: Services, environment: [String: String]) {
    guard let value = environment["OVERRIDE_NOW"], let interval = Double(value) else { return }
    services.timeService.now = Date(timeIntervalSince1970: interval)
  }
}

private struct OverrideDates: PostInitCommand {
  private static var timer: Timer?

  static func perform(with services: Services, environment: [String: String]) {
    guard let value = environment["OVERRIDE_NOWS"] else { return }
    let components = value.components(separatedBy: ",")

    guard components.count == 2, let value1 = Double(components[0]), let value2 = Double(components[1]) else { return }
    let date1 = Date(timeIntervalSince1970: value1)
    let date2 = Date(timeIntervalSince1970: value2)

    var flag = true
    timer = .scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
      services.timeService.now = flag ? date1 : date2
      flag.toggle()
    }
  }
}

private struct OverrideVideo: PostInitCommand {
  static func perform(with services: Services, environment: [String: String]) {
    guard let value = environment["OVERRIDE_VIDEO"], let video = Data(base64Encoded: value) else { return }

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

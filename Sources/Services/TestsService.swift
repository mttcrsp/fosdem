#if DEBUG
import UIKit

final class TestsService {
  private let preInitCommands: [TestsServicePreInitCommand.Type] = [
    ResetDefaults.self,
  ]

  private let postInitCommands: [TestsServicePostInitCommand.Type] = [
    OverrideDate.self,
    OverrideDates.self,
    OverrideVideo.self,
    PreventOnboarding.self,
    PreventScheduleUpdates.self,
    SetFavoriteEvents.self,
    SetFavoriteTracks.self,
    SetLiveTimerInterval.self,
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

private protocol TestsServicePreInitCommand {
  static func perform(with environment: [String: String])
}

private protocol TestsServicePostInitCommand {
  static func perform(with services: Services, environment: [String: String])
}

private struct ResetDefaults: TestsServicePreInitCommand {
  static func perform(with environment: [String: String]) {
    guard let name = Bundle.main.bundleIdentifier, environment["RESET_DEFAULTS"] != nil else { return }
    UserDefaults.standard.removePersistentDomain(forName: name)
  }
}

private struct PreventOnboarding: TestsServicePostInitCommand {
  static func perform(with services: Services, environment: [String: String]) {
    guard environment["ENABLE_ONBOARDING"] != nil else { return }
    services.launchService.markAsLaunched()
  }
}

private struct PreventScheduleUpdates: TestsServicePostInitCommand {
  static func perform(with services: Services, environment: [String: String]) {
    guard environment["ENABLE_SCHEDULE_UPDATES"] != nil else { return }
    services.scheduleService = nil
  }
}

private struct SetFavoriteEvents: TestsServicePostInitCommand {
  static func perform(with services: Services, environment: [String: String]) {
    guard let value = environment["FAVORITE_EVENTS"] else { return }
    let identifiers = Set(value.components(separatedBy: ",").compactMap(Int.init))
    services.favoritesService.setEventsIdentifiers(identifiers)
  }
}

private struct SetFavoriteTracks: TestsServicePostInitCommand {
  static func perform(with services: Services, environment: [String: String]) {
    guard let value = environment["FAVORITE_TRACKS"] else { return }
    let identifiers = Set(value.components(separatedBy: ","))
    services.favoritesService.setTracksIdentifiers(identifiers)
  }
}

private struct OverrideDate: TestsServicePostInitCommand {
  static func perform(with services: Services, environment: [String: String]) {
    guard let value = environment["SOON_DATE"], let interval = Double(value) else { return }
    services.debugService.override(Date(timeIntervalSince1970: interval))
  }
}

private struct SetLiveTimerInterval: TestsServicePostInitCommand {
  static func perform(with services: Services, environment: [String: String]) {
    guard let value = environment["LIVE_INTERVAL"], let interval = TimeInterval(value) else { return }
    services.liveService = LiveService(timeInterval: interval)
  }
}

private struct OverrideDates: TestsServicePostInitCommand {
  private static var timer: Timer?

  static func perform(with services: Services, environment: [String: String]) {
    guard let value = environment["LIVE_DATES"] else { return }
    let components = value.components(separatedBy: ",")

    guard components.count == 2, let value1 = Double(components[0]), let value2 = Double(components[1]) else { return }
    let date1 = Date(timeIntervalSince1970: value1)
    let date2 = Date(timeIntervalSince1970: value2)

    var flag = true
    timer = .scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
      services.debugService.override(flag ? date1 : date2)
      flag.toggle()
    }
  }
}

private struct OverrideVideo: TestsServicePostInitCommand {
  static func perform(with services: Services, environment: [String: String]) {
    guard let value = environment["VIDEO"], let video = Data(base64Encoded: value) else { return }

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

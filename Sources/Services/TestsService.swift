#if DEBUG
import UIKit

final class TestsService {
  private var timer: Timer?

  private var environment: [String: String] {
    ProcessInfo.processInfo.environment
  }

  var shouldResetDefaults: Bool {
    environment["RESET_DEFAULTS"] != nil
  }

  var shouldUpdateSchedule: Bool {
    environment["ENABLE_SCHEDULE_UPDATES"] != nil
  }

  var shouldDiplayOnboarding: Bool {
    environment["ENABLE_ONBOARDING"] != nil
  }

  var liveTimerInterval: TimeInterval? {
    if let string = environment["LIVE_INTERVAL"] {
      return TimeInterval(string)
    } else {
      return nil
    }
  }

  var favoriteTracksIdentifiers: Set<String>? {
    if let value = environment["FAVORITE_TRACKS"] {
      return Set(value.components(separatedBy: ","))
    } else {
      return nil
    }
  }

  var favoriteEventsIdentifiers: Set<Int>? {
    if let value = environment["FAVORITE_EVENTS"] {
      return Set(value.components(separatedBy: ",").compactMap(Int.init))
    } else {
      return nil
    }
  }

  var video: Data? {
    if let base64 = environment["VIDEO"] {
      return Data(base64Encoded: base64)
    } else {
      return nil
    }
  }

  var date: Date? {
    if let string = environment["SOON_DATE"], let value = Double(string) {
      return Date(timeIntervalSince1970: value)
    } else {
      return nil
    }
  }

  var dates: (Date, Date)? {
    guard let string = environment["LIVE_DATES"] else {
      return nil
    }

    let components = string.components(separatedBy: ",")
    guard components.count == 2, let value1 = Double(components[0]), let value2 = Double(components[1]) else {
      return nil
    }

    let date1 = Date(timeIntervalSince1970: value1)
    let date2 = Date(timeIntervalSince1970: value2)
    return (date1, date2)
  }

  func startTogglingDates(_ dates: (Date, Date), handler: @escaping (Date) -> Void) {
    let (date1, date2) = dates

    var flag = true
    timer = .scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
      handler(flag ? date1 : date2)
      flag.toggle()
    }
  }
}
#endif

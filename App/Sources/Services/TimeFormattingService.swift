import UIKit

enum DisplayTimeZone: Int, CaseIterable {
  case conference, current

  /// NZDT and HST make for good test values. You can test out different time
  /// zones by setting the TZ environment variable.
  var timeZone: TimeZone {
    switch self {
    case .conference: .conference
    case .current: .current
    }
  }
}

private let didChangeDisplayTimeZone = Notification.Name("com.mttcrsp.fosdem.TimeFormattingService.didChangeDisplayTimeZone")
private let displayTimeZoneKey = "com.mttcrsp.fosdem.TimeFormattingService.displayTimeZoneKey"

final class TimeFormattingService {
  private lazy var timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    formatter.timeZone = displayTimeZone.timeZone
    return formatter
  }()

  private lazy var weekdayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE"
    formatter.timeZone = displayTimeZone.timeZone
    return formatter
  }()

  private lazy var weekdayWithShortDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE, d MMMM"
    formatter.timeZone = displayTimeZone.timeZone
    return formatter
  }()

  private let notificationCenter = NotificationCenter()
  private let userDefaults: UserDefaults

  init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
  }

  var displayTimeZone: DisplayTimeZone {
    set {
      for formatter in [timeFormatter, weekdayFormatter, weekdayWithShortDateFormatter] {
        formatter.timeZone = newValue.timeZone
      }
      notificationCenter.post(name: didChangeDisplayTimeZone, object: nil)
      userDefaults.set(newValue.rawValue, forKey: displayTimeZoneKey)
    }
    get {
      guard userDefaults.object(forKey: displayTimeZoneKey) != nil else { return .conference }
      return DisplayTimeZone(rawValue: userDefaults.integer(forKey: displayTimeZoneKey)) ?? .conference
    }
  }

  func addObserverForDisplayTimeZoneChanges(_ handler: @escaping () -> Void) -> NSObjectProtocol {
    notificationCenter.addObserver(forName: didChangeDisplayTimeZone, object: nil, queue: nil) { _ in
      handler()
    }
  }

  func removeObserverForDisplayTimeZoneChanges(_ observer: NSObjectProtocol) {
    notificationCenter.removeObserver(observer)
  }

  func time(from date: Date) -> String {
    timeFormatter.string(from: date)
  }

  func weekday(from date: Date) -> String {
    weekdayFormatter.string(from: date)
  }

  func weekdayWithShortDate(from date: Date) -> String {
    weekdayWithShortDateFormatter.string(from: date)
  }
}

/// @mockable
protocol TimeFormattingServiceProtocol: AnyObject {
  var displayTimeZone: DisplayTimeZone { get set }
  func addObserverForDisplayTimeZoneChanges(_ handler: @escaping () -> Void) -> NSObjectProtocol
  func removeObserverForDisplayTimeZoneChanges(_ observer: NSObjectProtocol)
  func time(from date: Date) -> String
  func weekday(from date: Date) -> String
  func weekdayWithShortDate(from date: Date) -> String
}

extension TimeFormattingService: TimeFormattingServiceProtocol {}

protocol HasTimeFormattingService {
  var timeFormattingService: TimeFormattingServiceProtocol { get }
}

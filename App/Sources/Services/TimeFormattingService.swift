import UIKit

enum FormattingTimeZone: Int, CaseIterable {
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

final class DateFormattingService {
  private static let domain = "com.mttcrsp.fosdem.DateFormattingService"
  private static let didChangeFormattingTimeZone = Notification.Name("\(domain).didChangeFormattingTimeZone")
  private static let formattingTimeZoneKey = "\(domain).formattingTimeZone"
  
  private lazy var timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    formatter.timeZone = formattingTimeZone.timeZone
    return formatter
  }()

  private lazy var weekdayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE"
    formatter.timeZone = formattingTimeZone.timeZone
    return formatter
  }()

  private lazy var weekdayWithShortDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE, d MMMM"
    formatter.timeZone = formattingTimeZone.timeZone
    return formatter
  }()

  private let notificationCenter = NotificationCenter()
  private let userDefaults: UserDefaults

  init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
  }

  var formattingTimeZone: FormattingTimeZone {
    set {
      for formatter in [timeFormatter, weekdayFormatter, weekdayWithShortDateFormatter] {
        formatter.timeZone = newValue.timeZone
      }
      notificationCenter.post(name: Self.didChangeFormattingTimeZone, object: nil)
      userDefaults.set(newValue.rawValue, forKey: Self.formattingTimeZoneKey)
    }
    get {
      guard userDefaults.object(forKey: Self.formattingTimeZoneKey) != nil else { return .conference }
      return FormattingTimeZone(rawValue: userDefaults.integer(forKey: Self.formattingTimeZoneKey)) ?? .conference
    }
  }

  func addObserverForFormattingTimeZoneChanges(_ handler: @escaping () -> Void) -> NSObjectProtocol {
    notificationCenter.addObserver(forName: Self.didChangeFormattingTimeZone, object: nil, queue: nil) { _ in
      handler()
    }
  }

  func removeObserverForFormattingTimeZoneChanges(_ observer: NSObjectProtocol) {
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
protocol DateFormattingServiceProtocol: AnyObject {
  var formattingTimeZone: FormattingTimeZone { get set }
  func addObserverForFormattingTimeZoneChanges(_ handler: @escaping () -> Void) -> NSObjectProtocol
  func removeObserverForFormattingTimeZoneChanges(_ observer: NSObjectProtocol)
  func time(from date: Date) -> String
  func weekday(from date: Date) -> String
  func weekdayWithShortDate(from date: Date) -> String
}

extension DateFormattingService: DateFormattingServiceProtocol {}

protocol HasDateFormattingService {
  var dateFormattingService: DateFormattingServiceProtocol { get }
}

import Foundation

struct TimeService {
  var now: () -> Date
  var startMonitoring: () -> Void
  var stopMonitoring: () -> Void
  var addObserver: (@escaping () -> Void) -> NSObjectProtocol
}

extension TimeService {
  init(timeInterval: TimeInterval = 10, timerProvider: TimeServiceProvider = TimeServiceTimerProvider()) {
    let notificationCenter = NotificationCenter()

    func timerDidFire() {
      notificationCenter.post(Notification(name: .timeDidChange))
    }

    var timer: TimeServiceTimer?

    startMonitoring = {
      timer = timerProvider.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { _ in
        timerDidFire()
      }
    }

    stopMonitoring = {
      timer?.invalidate()
      timer = nil
    }

    addObserver = { handler in
      notificationCenter.addObserver(forName: .timeDidChange, object: nil, queue: nil, using: { _ in handler() })
    }

    now = {
      #if DEBUG
      let calendar = Calendar.autoupdatingCurrent
      let timeZone = TimeZone(identifier: "Europe/Brussels")
      let components = DateComponents(timeZone: timeZone, year: 2023, month: 2, day: 4, hour: 12, minute: 45)
      return calendar.date(from: components) ?? Date()
      #else
      return Date()
      #endif
    }
  }
}

private final class TimeServiceTimerProvider: TimeServiceProvider {
  func scheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping (TimeServiceTimer) -> Void) -> TimeServiceTimer {
    Timer.scheduledTimer(withTimeInterval: interval, repeats: repeats, block: block)
  }
}

extension Timer: TimeServiceTimer {}

private extension Notification.Name {
  static var timeDidChange: Notification.Name { Notification.Name(#function) }
}

/// @mockable
protocol TimeServiceProtocol {
  #if DEBUG
  var now: () -> Date { get set }
  #else
  var now: () -> Date { get }
  #endif

  var startMonitoring: () -> Void { get }
  var stopMonitoring: () -> Void { get }
  var addObserver: (@escaping () -> Void) -> NSObjectProtocol { get }
}

extension TimeService: TimeServiceProtocol {}

/// @mockable
protocol TimeServiceTimer {
  func invalidate()
}

/// @mockable
protocol TimeServiceProvider {
  func scheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping (TimeServiceTimer) -> Void) -> TimeServiceTimer
}

protocol HasTimeService {
  var timeService: TimeServiceProtocol { get set }
}

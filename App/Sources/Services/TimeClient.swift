import Foundation

struct TimeClient {
  var now: () -> Date
  var startMonitoring: () -> Void
  var stopMonitoring: () -> Void
  var addObserver: (@escaping () -> Void) -> NSObjectProtocol
}

extension TimeClient {
  init(timeInterval: TimeInterval = 10, timerProvider: TimeClientProvider = TimeClientTimerProvider()) {
    let notificationCenter = NotificationCenter()

    func timerDidFire() {
      notificationCenter.post(Notification(name: .timeDidChange))
    }

    var timer: TimeClientTimer?

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

private final class TimeClientTimerProvider: TimeClientProvider {
  func scheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping (TimeClientTimer) -> Void) -> TimeClientTimer {
    Timer.scheduledTimer(withTimeInterval: interval, repeats: repeats, block: block)
  }
}

extension Timer: TimeClientTimer {}

private extension Notification.Name {
  static var timeDidChange: Notification.Name { Notification.Name(#function) }
}

/// @mockable
protocol TimeClientProtocol {
  #if DEBUG
  var now: () -> Date { get set }
  #else
  var now: () -> Date { get }
  #endif

  var startMonitoring: () -> Void { get }
  var stopMonitoring: () -> Void { get }
  var addObserver: (@escaping () -> Void) -> NSObjectProtocol { get }
}

extension TimeClient: TimeClientProtocol {}

/// @mockable
protocol TimeClientTimer {
  func invalidate()
}

/// @mockable
protocol TimeClientProvider {
  func scheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping (TimeClientTimer) -> Void) -> TimeClientTimer
}

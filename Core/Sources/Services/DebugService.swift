#if DEBUG
import Foundation

final class DebugService {
  var now: Date {
    date ?? Date()
  }

  private var date: Date?

  init() {
    let calendar = Calendar.autoupdatingCurrent
    let timeZone = TimeZone(identifier: "Europe/Brussels")
    let components = DateComponents(timeZone: timeZone, year: 2021, month: 2, day: 6, hour: 12, minute: 45)
    date = calendar.date(from: components)
  }

  func override(_ date: Date) {
    self.date = date
  }
}
#endif

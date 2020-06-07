#if DEBUG
import Foundation

final class DebugService {
  var now: Date {
    date ?? Date()
  }

  private var date: Date?

  init() {
    let calendar = Calendar.autoupdatingCurrent
    let components = DateComponents(year: 2020, month: 2, day: 1, hour: 10, minute: 45)
    date = calendar.date(from: components)
  }

  func override(_ date: Date) {
    self.date = date
  }
}
#endif

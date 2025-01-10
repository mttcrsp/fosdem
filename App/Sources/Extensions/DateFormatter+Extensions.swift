import Foundation

extension DateFormatter {
  static let `default`: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }()

  static var weekday: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE"
    return formatter
  }()

  static var weekdayWithShortDate: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE, d MMMM"
    return formatter
  }()
}

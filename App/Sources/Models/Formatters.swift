import Foundation

final class TrackFormatter {
  func formattedName(from name: String) -> String {
    let devroomSuffix = " devroom"
    if name.hasSuffix(devroomSuffix) {
      return String(name[...name.index(name.endIndex, offsetBy: -devroomSuffix.count)])
    } else {
      return name
    }
  }
}

final class SummaryFormatter {
  func formattedSummary(from summary: String) -> String {
    var summary = summary
    summary = summary.replacingOccurrences(of: "\t", with: " ")
    summary = summary.replacingOccurrences(of: "\n", with: "\n\n")
    return summary
  }
}

final class PeopleFormatter {
  func formattedPeople(from people: [Person]) -> String {
    people.map { person in person.name }.joined(separator: ", ")
  }
}

final class DurationFormatter {
  func duration(from duration: DateComponents) -> String? {
    Self.formatter.string(from: duration)
  }

  private static let formatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.minute]
    return formatter
  }()
}

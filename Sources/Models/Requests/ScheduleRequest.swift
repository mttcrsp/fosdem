import Foundation

struct ScheduleRequest: NetworkRequest {
  enum Error: CustomNSError {
    case notFound
  }

  let year: Int

  var url: URL {
    URL(string: "https://fosdem.org/")!
      .appendingPathComponent(year.description)
      .appendingPathComponent("schedule")
      .appendingPathComponent("xml")
  }

  func decode(_ data: Data?, response: HTTPURLResponse?) throws -> Schedule {
    let parser = ScheduleXMLParser(data: data ?? Data())

    if parser.parse(), let schedule = parser.schedule {
      return schedule
    }

    if let validationError = parser.validationError {
      throw validationError
    }

    if let parseError = parser.parseError {
      throw parseError
    }

    throw NSError(domain: "com.mttcrsp.ScheduleRequest", code: 1)
  }
}

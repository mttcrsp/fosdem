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
    guard let data, response?.statusCode != 404 else {
      throw Error.notFound
    }

    let parser = ScheduleXMLParser(data: data)

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

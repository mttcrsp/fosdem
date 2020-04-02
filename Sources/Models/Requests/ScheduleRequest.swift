import Foundation

struct ScheduleRequest: NetworkRequest {
    let year: Int

    var url: URL {
        URL(string: "https://fosdem.org/")!
            .appendingPathComponent(year.description)
            .appendingPathComponent("schedule")
            .appendingPathComponent("xml")
    }

    func decode(_ data: Data) throws -> Schedule {
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

        throw NSError(domain: "org.fosdem.ScheduleRequest", code: 1)
    }
}

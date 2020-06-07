import Foundation

final class ScheduleXMLParser: NSObject, XMLParserDelegate {
  fileprivate struct EventState {
    var attachments: [Attachment] = [], people: [Person] = [], links: [Link] = []
  }

  fileprivate struct DayState {
    var events: [Event] = [], rooms: [Room] = []
  }

  fileprivate struct ScheduleState {
    var days: [Day] = [], conference: Conference?
  }

  fileprivate struct Error {
    let element: String, value: CustomStringConvertible
  }

  private typealias Element = (name: String, attributes: [String: String])

  private var scheduleState = ScheduleState()
  private var eventState = EventState()
  private var dayState = DayState()
  private var stack: [Element] = []

  private(set) var schedule: Schedule?
  private(set) var parseError: Swift.Error?
  private(set) var validationError: Swift.Error?

  private let parser: XMLParser

  init(data: Data) {
    parser = XMLParser(data: data)
    super.init()
    parser.delegate = self
  }

  func parse() -> Bool {
    parser.parse()
    return schedule != nil
  }

  func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
    stack.append((elementName, attributeDict))
  }

  func parser(_ parser: XMLParser, foundCharacters string: String) {
    let value = string.trimmingCharacters(in: .whitespacesAndNewlines)
    if !value.isEmpty {
      var (name, attributes) = stack.removeLast()
      attributes["value", default: ""] += value
      stack.append((name, attributes))
    }
  }

  func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
    let (name, attributes) = stack.removeLast()

    do {
      switch name {
      case Link.name:
        try didParseLink(with: attributes)
      case Person.name:
        try didParsePerson(with: attributes)
      case Attachment.name:
        try didParseAttachment(with: attributes)
      case let name where Event.attributesNames.contains(name) && stack.last?.name == Event.name:
        didParseEventAttribute(withName: name, attributes: attributes)
      case Event.name:
        try didParseEvent(with: attributes)
      case Room.name:
        try didParseRoom(with: attributes)
      case Day.name:
        try didParseDay(with: attributes)
      case let name where Conference.attributesNames.contains(name) && stack.last?.name == Conference.name:
        didParseConferenceAttribute(withName: name, attributes: attributes)
      case Conference.name:
        try didParseConference(with: attributes)
      case Schedule.name:
        try didParseSchedule()
      default:
        break
      }
    } catch {
      parseError = error
    }
  }

  func parser(_ parser: XMLParser, parseErrorOccurred parseError: Swift.Error) {
    self.parseError = parseError
  }

  func parser(_ parser: XMLParser, validationErrorOccurred validationError: Swift.Error) {
    self.validationError = validationError
  }

  private func didParseLink(with attributes: [String: String]) throws {
    let link = try Link(attributes: attributes)
    eventState.links.append(link)
  }

  private func didParsePerson(with attributes: [String: String]) throws {
    let person = try Person(attributes: attributes)
    eventState.people.append(person)
  }

  private func didParseAttachment(with attributes: [String: String]) throws {
    let attachment = try Attachment(attributes: attributes)
    eventState.attachments.append(attachment)
  }

  private func didParseEvent(with attributes: [String: String]) throws {
    guard let day = stack.first(where: { element in element.name == "day" }) else {
      throw Error(element: "event", value: "missing container day")
    }

    let event = try Event(attributes: attributes, state: eventState, dayAttributes: day.attributes)
    dayState.events.append(event)
    eventState = EventState()
  }

  private func didParseRoom(with attributes: [String: String]) throws {
    let room = try Room(attributes: attributes, events: dayState.events)
    dayState.rooms.append(room)
    dayState.events = []
  }

  private func didParseDay(with attributes: [String: String]) throws {
    let day = try Day(attributes: attributes, state: dayState)
    scheduleState.days.append(day)
    dayState = DayState()
  }

  private func didParseConference(with attributes: [String: String]) throws {
    scheduleState.conference = try Conference(attributes: attributes)
  }

  private func didParseSchedule() throws {
    guard let conference = scheduleState.conference else {
      throw Error(element: "schedule", value: "missing conference")
    }
    schedule = Schedule(conference: conference, days: scheduleState.days)
  }

  private func didParseEventAttribute(withName name: String, attributes: [String: String]) {
    var (eventName, eventAttributes) = stack.removeLast()
    eventAttributes[name] = attributes["value"]
    stack.append((eventName, eventAttributes))
  }

  private func didParseConferenceAttribute(withName name: String, attributes: [String: String]) {
    var (conferenceName, conferenceAttributes) = stack.removeLast()
    conferenceAttributes[name] = attributes["value"]
    stack.append((conferenceName, conferenceAttributes))
  }
}

extension ScheduleXMLParser.Error: Swift.Error, CustomNSError {
  var localizedDescription: String {
    "Malfomed \(element) found: \(value)"
  }

  var errorUserInfo: [String: Any] {
    [NSLocalizedDescriptionKey: localizedDescription]
  }

  static var errorDomain: String {
    "com.mttcrsp.fosdem.\(String(describing: ScheduleXMLParser.self))"
  }
}

private typealias Error = ScheduleXMLParser.Error

private extension Link {
  static var name: String {
    "link"
  }

  init(attributes: [String: String]) throws {
    guard let href = attributes["href"], let name = attributes["value"] else {
      throw Error(element: "link", value: attributes)
    }

    // Links returned by the FOSDEM API are sometimes malformed. Most of the
    // time the issue is caused by some leftover whitespaces at the end of
    // the URL.
    self.init(name: name, url: URL(string: href))
  }
}

private extension Person {
  static var name: String {
    "person"
  }

  init(attributes: [String: String]) throws {
    guard let idRawValue = attributes["id"], let name = attributes["value"] else {
      throw Error(element: "person", value: attributes)
    }

    guard let id = Int(idRawValue) else {
      throw Error(element: "person id", value: idRawValue)
    }

    self.init(id: id, name: name)
  }
}

private extension Attachment {
  static var name: String {
    "attachment"
  }

  init(attributes: [String: String]) throws {
    guard let href = attributes["href"], let typeRawValue = attributes["type"] else {
      throw Error(element: "attachment", value: attributes)
    }

    guard let type = AttachmentType(rawValue: typeRawValue) else {
      throw Error(element: "attachment type", value: typeRawValue)
    }

    guard let url = URL(string: href) else {
      throw Error(element: "attachment url", value: href)
    }

    self.init(type: type, url: url, name: attributes["value"])
  }
}

private extension Event {
  static var name: String {
    "event"
  }

  static var attributesNames: Set<String> {
    ["start", "duration", "room", "slug", "title", "subtitle", "track", "type", "language", "abstract", "description"]
  }

  init(attributes: [String: String], state: ScheduleXMLParser.EventState, dayAttributes: [String: String]) throws {
    guard let idRawValue = attributes["id"], let room = attributes["room"], let track = attributes["track"], let title = attributes["title"], let startRawValue = attributes["start"], let durationRawValue = attributes["duration"] else {
      throw Error(element: "event", value: attributes)
    }

    guard let id = Int(idRawValue) else {
      throw Error(element: "event id", value: idRawValue)
    }

    let durationComponents = durationRawValue.components(separatedBy: ":")
    guard durationComponents.count == 2, let durationHour = Int(durationComponents[0]), let durationMinute = Int(durationComponents[1]) else {
      throw Error(element: "event duration", value: durationRawValue)
    }

    let startComponents = startRawValue.components(separatedBy: ":")
    guard startComponents.count == 2, let startHour = Int(startComponents[0]), let startMinute = Int(startComponents[1]) else {
      throw Error(element: "event start", value: startRawValue)
    }

    let start = DateComponents(hour: startHour, minute: startMinute)
    let duration = DateComponents(hour: durationHour, minute: durationMinute)

    guard let dateRawValue = dayAttributes["date"] else {
      throw Error(element: "day", value: "missing date")
    }

    guard let dateWithoutTime = DateFormatter.default.date(from: dateRawValue) else {
      throw Error(element: "day date", value: dateRawValue)
    }

    guard let date = Calendar.autoupdatingCurrent.date(byAdding: start, to: dateWithoutTime) else {
      throw Error(element: "day date time", value: start)
    }

    let summary = attributes["summary"]
    let subtitle = attributes["subtitle"]
    let abstract = attributes["abstract"]
    self.init(id: id, room: room, track: track, title: title, summary: summary, subtitle: subtitle, abstract: abstract, date: date, start: start, duration: duration, links: state.links, people: state.people, attachments: state.attachments)
  }
}

private extension Room {
  static var name: String {
    "room"
  }

  init(attributes: [String: String], events: [Event]) throws {
    guard let name = attributes["name"] else {
      throw Error(element: "room", value: attributes)
    }

    self.init(name: name, events: events)
  }
}

private extension Day {
  static var name: String {
    "day"
  }

  init(attributes: [String: String], state: ScheduleXMLParser.DayState) throws {
    guard let indexRawValue = attributes["index"], let dateRawValue = attributes["date"] else {
      throw Error(element: "day", value: attributes)
    }

    guard let index = Int(indexRawValue) else {
      throw Error(element: "day index", value: indexRawValue)
    }

    guard let date = DateFormatter.default.date(from: dateRawValue) else {
      throw Error(element: "day date", value: dateRawValue)
    }

    // The format used by the Schedule API changed slightly between 2012 and
    // 2013 when a room entity was introduced.
    let roomsEvents = state.rooms.flatMap { room in room.events }
    let allEvents = roomsEvents + state.events
    self.init(index: index, date: date, events: allEvents)
  }
}

private extension Conference {
  static var name: String {
    "conference"
  }

  static var attributesNames: Set<String> {
    ["title", "subtitle", "venue", "city", "start", "end", "days", "day_change", "timeslot_duration"]
  }

  init(attributes: [String: String]) throws {
    guard let title = attributes["title"], let venue = attributes["venue"], let city = attributes["city"], let startRawValue = attributes["start"], let endRawValue = attributes["end"] else {
      throw Error(element: "conference", value: attributes)
    }

    guard let start = DateFormatter.default.date(from: startRawValue) else {
      throw Error(element: "conference start", value: startRawValue)
    }

    guard let end = DateFormatter.default.date(from: endRawValue) else {
      throw Error(element: "conference end", value: endRawValue)
    }

    let subtitle = attributes["subtitle"]
    self.init(title: title, subtitle: subtitle, venue: venue, city: city, start: start, end: end)
  }
}

private extension Schedule {
  static var name: String {
    "schedule"
  }
}

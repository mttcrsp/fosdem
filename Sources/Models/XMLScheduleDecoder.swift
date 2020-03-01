import Foundation

final class XMLScheduleDecoder: NSObject, XMLParserDelegate {
    fileprivate struct EventState {
        var attachments: [Attachment] = [], people: [Person] = [], links: [Link] = []
    }

    fileprivate struct DayState {
        var events: [Event] = [], rooms: [Room] = []
    }

    fileprivate struct ScheduleState {
        var days: [Day] = [], conference: Conference?
    }

    private typealias Element = (name: String, attributes: [String: String])

    private var scheduleState = ScheduleState()
    private var eventState = EventState()
    private var dayState = DayState()
    private var stack: [Element] = []

    private(set) var schedule: Schedule?
    private(set) var parseError: Error?
    private(set) var validationError: Error?

    private let parser: XMLParser

    init(data: Data) {
        parser = XMLParser(data: data)
        super.init()
        parser.delegate = self
    }

    func parse() -> Bool {
        parser.parse()
    }

    func parser(_: XMLParser, didStartElement name: String, namespaceURI _: String?, qualifiedName _: String?, attributes attributeDict: [String: String] = [:]) {
        stack.append((name, attributeDict))
    }

    func parser(_: XMLParser, foundCharacters string: String) {
        let value = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if !value.isEmpty {
            var (name, attributes) = stack.removeLast()
            attributes["value", default: ""] += value
            stack.append((name, attributes))
        }
    }

    func parser(_: XMLParser, didEndElement name: String, namespaceURI _: String?, qualifiedName _: String?) {
        let (name, attributes) = stack.removeLast()

        switch name {
        case Link.name:
            didParseLink(with: attributes)
        case Person.name:
            didParsePerson(with: attributes)
        case Attachment.name:
            didParseAttachment(with: attributes)
        case let name where Event.attributesNames.contains(name) && stack.last?.name == Event.name:
            didParseEventAttribute(withName: name, attributes: attributes)
        case Event.name:
            didParseEvent(with: attributes)
        case Room.name:
            didParseRoom(with: attributes)
        case Day.name:
            didParseDay(with: attributes)
        case let name where Conference.attributesNames.contains(name) && stack.last?.name == Conference.name:
            didParseConferenceAttribute(withName: name, attributes: attributes)
        case Conference.name:
            didParseConference(with: attributes)
        case Schedule.name:
            didParseSchedule()
        default:
            break
        }
    }

    func parser(_: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = parseError
    }

    func parser(_: XMLParser, validationErrorOccurred validationError: Error) {
        self.validationError = validationError
    }

    private var entityNames: Set<String> {
        [Schedule.name, Conference.name, Day.name, Room.name, Event.name, Person.name, Attachment.name, Link.name]
    }

    private func didParseLink(with attributes: [String: String]) {
        guard let link = Link(attributes: attributes) else { return }
        eventState.links.append(link)
    }

    private func didParsePerson(with attributes: [String: String]) {
        guard let person = Person(attributes: attributes) else { return }
        eventState.people.append(person)
    }

    private func didParseAttachment(with attributes: [String: String]) {
        guard let attachment = Attachment(attributes: attributes) else { return }
        eventState.attachments.append(attachment)
    }

    private func didParseEvent(with attributes: [String: String]) {
        guard let event = Event(attributes: attributes, state: eventState) else { return }
        dayState.events.append(event)
        eventState = .init()
    }

    private func didParseRoom(with attributes: [String: String]) {
        guard let room = Room(attributes: attributes, events: dayState.events) else { return }
        dayState.rooms.append(room)
        dayState.events = []
    }

    private func didParseDay(with attributes: [String: String]) {
        guard let day = Day(attributes: attributes, state: dayState) else { return }
        scheduleState.days.append(day)
        dayState = .init()
    }

    private func didParseConference(with attributes: [String: String]) {
        guard let conference = Conference(attributes: attributes) else { return }
        scheduleState.conference = conference
    }

    private func didParseSchedule() {
        guard let conference = scheduleState.conference else { return }
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

private extension Link {
    static var name: String {
        "link"
    }

    init?(attributes: [String: String]) {
        guard let href = attributes["href"], let name = attributes["value"] else {
            assertionFailure("Malfomed link found \(attributes)")
            return nil
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

    init?(attributes: [String: String]) {
        guard let idRawValue = attributes["id"], let name = attributes["value"] else {
            assertionFailure("Malfomed person found \(attributes)")
            return nil
        }

        guard let id = Int(idRawValue) else {
            assertionFailure("Malfomed person id found \(idRawValue)")
            return nil
        }

        self.init(id: id, name: name)
    }
}

private extension Attachment {
    static var name: String {
        "attachment"
    }

    init?(attributes: [String: String]) {
        guard let href = attributes["href"], let typeRawValue = attributes["type"] else {
            assertionFailure("Malfomed attachment found \(attributes)")
            return nil
        }

        guard let type = AttachmentType(rawValue: typeRawValue) else {
            assertionFailure("Malfomed attachment url found \(href)")
            return nil
        }

        guard let url = URL(string: href) else {
            assertionFailure("Malfomed attachment url found \(href)")
            return nil
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

    init?(attributes: [String: String], state: XMLScheduleDecoder.EventState) {
        guard let idRawValue = attributes["id"], let room = attributes["room"], let track = attributes["track"], let title = attributes["title"], let startRawValue = attributes["start"], let durationRawValue = attributes["duration"] else {
            assertionFailure("Malfomed event found \(attributes)")
            return nil
        }

        guard let id = Int(idRawValue) else {
            assertionFailure("Malformed event id found \(idRawValue)")
            return nil
        }

        let startComponents = startRawValue.components(separatedBy: ":")
        guard startComponents.count == 2, let startHour = Int(startComponents[0]), let startMinute = Int(startComponents[1]) else {
            assertionFailure("Malformed event start found \(startRawValue)")
            return nil
        }

        let durationComponents = durationRawValue.components(separatedBy: ":")
        guard durationComponents.count == 2, let durationHour = Int(durationComponents[0]), let durationMinute = Int(durationComponents[1]) else {
            assertionFailure("Malformed event duration found \(durationRawValue)")
            return nil
        }

        let summary = attributes["summary"]
        let subtitle = attributes["subtitle"]
        let abstract = attributes["abstract"]
        let start = DateComponents(hour: startHour, minute: startMinute)
        let duration = DateComponents(hour: durationHour, minute: durationMinute)
        self.init(id: id, room: room, track: track, title: title, summary: summary, subtitle: subtitle, abstract: abstract, start: start, duration: duration, links: state.links, people: state.people, attachments: state.attachments)
    }
}

private extension Room {
    static var name: String {
        "room"
    }

    init?(attributes: [String: String], events: [Event]) {
        guard let name = attributes["name"] else {
            assertionFailure("Malfomed room found \(attributes)")
            return nil
        }

        self.init(name: name, events: events)
    }
}

private extension Day {
    static var name: String {
        "day"
    }

    init?(attributes: [String: String], state: XMLScheduleDecoder.DayState) {
        guard let indexRawValue = attributes["index"], let dateRawValue = attributes["date"] else {
            assertionFailure("Malfomed day found \(attributes)")
            return nil
        }

        guard let index = Int(indexRawValue) else {
            assertionFailure("Malfomed day index found \(indexRawValue)")
            return nil
        }

        guard let date = DateFormatter.default.date(from: dateRawValue) else {
            assertionFailure("Malfomed day date found \(dateRawValue)")
            return nil
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

    init?(attributes: [String: String]) {
        guard let title = attributes["title"], let venue = attributes["venue"], let city = attributes["city"], let startRawValue = attributes["start"], let endRawValue = attributes["end"] else {
            assertionFailure("Malfomed conference found \(attributes)")
            return nil
        }

        guard let start = DateFormatter.default.date(from: startRawValue) else {
            assertionFailure("Malfomed conference start found \(startRawValue)")
            return nil
        }

        guard let end = DateFormatter.default.date(from: endRawValue) else {
            assertionFailure("Malfomed conference end found \(endRawValue)")
            return nil
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

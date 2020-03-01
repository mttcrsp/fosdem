import Foundation

final class XMLScheduleDecoder: NSObject, XMLParserDelegate {
    private typealias Element = (elementName: String, attributesDict: [String: String])
    private var elementsStack: [Element] = []

    private var attachments: [Attachment] = []
    private var people: [Person] = []
    private var links: [Link] = []

    private var events: [Event] = []
    private var rooms: [Room] = []
    private var days: [Day] = []

    private var conference: Conference?

    private(set) var schedule: Schedule?
    private(set) var validationError: Error?
    private(set) var parseError: Error?

    private let parser: XMLParser

    init(data: Data) {
        parser = XMLParser(data: data)
        super.init()
        parser.delegate = self
    }

    func parse() -> Bool {
        parser.parse()
    }

    func parserDidStartDocument(_ parser: XMLParser) {
        print(#function, parser)
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        print(#function, parser)
    }

    func parser(_: XMLParser, didStartElement elementName: String, namespaceURI _: String?, qualifiedName _: String?, attributes attributeDict: [String: String] = [:]) {
        elementsStack.append((elementName, attributeDict))
    }

    func parser(_: XMLParser, foundCharacters string: String) {
        let value = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if !value.isEmpty {
            var (elementName, attributesDict) = elementsStack.removeLast()
            attributesDict["value", default: ""] += value
            elementsStack.append((elementName, attributesDict))
        }
    }

    func parser(_: XMLParser, didEndElement elementName: String, namespaceURI _: String?, qualifiedName _: String?) {
        let (elementName, attributesDict) = elementsStack.removeLast()

        if elementName == "link", let link = Link(attributesDict: attributesDict) {
            return links.append(link)
        }

        if elementName == "person", let person = Person(attributesDict: attributesDict) {
            return people.append(person)
        }

        if elementName == "attachment", let attachment = Attachment(attributesDict: attributesDict) {
            return attachments.append(attachment)
        }

        if eventElementsNames.contains(elementName), elementsStack.last?.elementName == "event" {
            var (eventElementName, eventAttributesDict) = elementsStack.removeLast()
            eventAttributesDict[elementName] = attributesDict["value"]
            return elementsStack.append((eventElementName, eventAttributesDict))
        }

        if conferenceElementsNames.contains(elementName), elementsStack.last?.elementName == "conference" {
            var (conferenceElementName, conferenceAttributesDict) = elementsStack.removeLast()
            conferenceAttributesDict[elementName] = attributesDict["value"]
            return elementsStack.append((conferenceElementName, conferenceAttributesDict))
        }

        if elementName == "event", let event = Event(attributesDict: attributesDict, links: links, people: people, attachments: attachments) {
            links = []; people = []; attachments = []
            return events.append(event)
        }

        if elementName == "room", let room = Room(attributesDict: attributesDict, events: events) {
            events = []
            return rooms.append(room)
        }

        if elementName == "day", let day = Day(attributesDict: attributesDict, rooms: rooms, events: events) {
            rooms = []; events = []
            return days.append(day)
        }

        if elementName == "conference", let conference = Conference(attributesDict: attributesDict) {
            self.conference = conference
            return
        }

        if elementName == "schedule", let conference = conference {
            schedule = Schedule(conference: conference, days: days)
            return print(schedule?.days.count as Any, schedule?.days.first?.events.count as Any)
        }
    }

    func parser(_: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = parseError
    }

    func parser(_: XMLParser, validationErrorOccurred validationError: Error) {
        self.validationError = validationError
    }

    private var entityNames: Set<String> {
        ["schedule", "conference", "day", "room", "event", "person", "attachment", "link"]
    }

    private var eventElementsNames: Set<String> {
        ["start", "duration", "room", "slug", "title", "subtitle", "track", "type", "language", "abstract", "description"]
    }

    private var conferenceElementsNames: Set<String> {
        ["title", "subtitle", "venue", "city", "start", "end", "days", "day_change", "timeslot_duration"]
    }
}

private extension Link {
    init?(attributesDict: [String: String]) {
        guard let href = attributesDict["href"], let name = attributesDict["value"] else {
            assertionFailure("Malfomed link found \(attributesDict)")
            return nil
        }

        self.init(name: name, url: URL(string: href))
    }
}

private extension Person {
    init?(attributesDict: [String: String]) {
        guard let idRawValue = attributesDict["id"], let name = attributesDict["value"] else {
            assertionFailure("Malfomed person found \(attributesDict)")
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
    init?(attributesDict: [String: String]) {
        guard let href = attributesDict["href"], let typeRawValue = attributesDict["type"] else {
            assertionFailure("Malfomed attachment found \(attributesDict)")
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

        self.init(type: type, url: url, name: attributesDict["value"])
    }
}

private extension Event {
    init?(attributesDict: [String: String], links: [Link], people: [Person], attachments: [Attachment]) {
        guard let idRawValue = attributesDict["id"], let room = attributesDict["room"], let track = attributesDict["track"], let title = attributesDict["title"], let startRawValue = attributesDict["start"], let durationRawValue = attributesDict["duration"] else {
            assertionFailure("Malfomed event found \(attributesDict)")
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

        self.init(
            id: id,
            room: room,
            track: track,
            title: title,
            summary: attributesDict["summary"],
            subtitle: attributesDict["subtitle"],
            abstract: attributesDict["abstract"],
            start: DateComponents(hour: startHour, minute: startMinute),
            duration: DateComponents(hour: durationHour, minute: durationMinute),
            links: links,
            people: people,
            attachments: attachments
        )
    }
}

private extension Room {
    init?(attributesDict: [String: String], events: [Event]) {
        guard let name = attributesDict["name"] else {
            assertionFailure("Malfomed room found \(attributesDict)")
            return nil
        }

        self.init(name: name, events: events)
    }
}

private extension Day {
    init?(attributesDict: [String: String], rooms: [Room], events: [Event]) {
        guard let indexRawValue = attributesDict["index"], let dateRawValue = attributesDict["date"] else {
            assertionFailure("Malfomed day found \(attributesDict)")
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

        let roomsEvents = rooms.flatMap { room in room.events }
        self.init(index: index, date: date, events: roomsEvents + events)
    }
}

private extension Conference {
    init?(attributesDict: [String: String]) {
        guard let title = attributesDict["title"], let venue = attributesDict["venue"], let city = attributesDict["city"], let startRawValue = attributesDict["start"], let endRawValue = attributesDict["end"] else {
            assertionFailure("Malfomed conference found \(attributesDict)")
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

        self.init(
            title: title,
            subtitle: attributesDict["subtitle"],
            venue: venue,
            city: city,
            start: start,
            end: end
        )
    }
}

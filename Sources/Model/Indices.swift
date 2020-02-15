struct Indices {
    let people: [Person]
    let tracks: [String]
    let tracksForDay: [[Track]]
    let eventsForTrack: [Track: [Event]]
    let eventForIdentifier: [String: Event]
}

extension Indices {
    init(schedule: Schedule) {
        var peopleSet: Set<Person> = []
        var eventsForTrack: [Track: [Event]] = [:]
        var eventForIdentifier: [String: Event] = [:]
        var tracksSetsForDay: [Int: Set<Track>] = [:]

        for day in schedule.days {
            for event in day.events {
                eventForIdentifier[event.id] = event
                eventsForTrack[event.track, default: []].append(event)
                tracksSetsForDay[day.index, default: []].insert(event.track)

                for person in event.people {
                    peopleSet.insert(person)
                }
            }
        }

        let tracksForDay = tracksSetsForDay
            .sorted { lhs, rhs in lhs.key < rhs.key }
            .map { _, value in value.sorted() }

        let tracks = Set(tracksSetsForDay.values
            .flatMap { tracks in tracks })
            .sorted()

        let people = peopleSet.sorted { lhs, rhs in
            lhs.name < rhs.name
        }

        self.init(
            people: people,
            tracks: tracks,
            tracksForDay: tracksForDay,
            eventsForTrack: eventsForTrack,
            eventForIdentifier: eventForIdentifier
        )
    }
}

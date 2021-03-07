import GRDB

struct ImportSchedule: PersistenceServiceWrite {
  let schedule: Schedule

  func perform(in database: Database) throws {
    for type in [Event.self, Track.self, Person.self, Participation.self] as [MutablePersistableRecord.Type] {
      try type.deleteAll(database)
    }

    for day in schedule.days {
      for event in day.events {
        try event.insert(database)

        let track = Track(name: event.track, day: day.index, date: day.date)
        try track.insert(database)

        for person in event.people {
          try person.insert(database)

          let participation = Participation(personID: person.id, eventID: event.id)
          try participation.insert(database)
        }
      }
    }
  }
}

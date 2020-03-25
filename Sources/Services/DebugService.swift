#if DEBUG

    import Foundation

    final class DebugService {
        private let persistenceService: PersistenceService

        init(persistenceService: PersistenceService) {
            self.persistenceService = persistenceService
        }

        func importSchedule() {
            guard let url = Bundle.main.url(forResource: "2020", withExtension: "xml") else {
                return assertionFailure("2020 schedule XML was not found in the main bundle")
            }

            guard let data = try? Data(contentsOf: url) else {
                return assertionFailure("Failed to load data for the 2020 schedule")
            }

            let parser = ScheduleXMLParser(data: data)

            guard parser.parse(), let schedule = parser.schedule else {
                let error = parser.validationError ?? parser.parseError
                return assertionFailure(error?.localizedDescription ?? "Failed to parse the 2020 schedule")
            }

            let importSchedule = ImportSchedule(schedule: schedule)
            persistenceService.performWrite(importSchedule) { error in
                assert(error == nil)
            }
        }
    }

#endif

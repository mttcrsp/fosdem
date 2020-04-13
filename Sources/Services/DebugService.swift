#if DEBUG
    import Foundation

    final class DebugService {
        var now: Date {
            date ?? Date()
        }

        private var date: Date?

        func override(_ date: Date) {
            self.date = date
        }
    }
#endif

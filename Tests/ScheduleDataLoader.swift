import Foundation
import XCTest

final class ScheduleDataLoader {
    func scheduleData(forYear year: Int) -> Data? {
        guard let url = Bundle(for: Self.self).url(forResource: "\(year)", withExtension: "xml") else {
            XCTFail("Unable to locate schedule for year '\(year)'")
            return nil
        }

        guard let data = try? Data(contentsOf: url) else {
            XCTFail("Unable to load schedule data for '\(year)'")
            return nil
        }

        return data
    }
}

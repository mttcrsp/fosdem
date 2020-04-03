@testable
import Fosdem
import XCTest

final class ScheduleServiceDefaultsMock: ScheduleServiceDefaults {
    var dictionary: [String: AnyHashable] = [:]

    func value(forKey key: String) -> Any? {
        dictionary[key]
    }

    func set(_ value: Any?, forKey defaultName: String) {
        if value == nil {
            dictionary[defaultName] = nil
            return
        }

        if let value = value as? AnyHashable {
            dictionary[defaultName] = value
            return
        }

        XCTFail("Unsupported value of type \(type(of: value)). Only Hashable types are supported by \(type(of: self))")
    }
}

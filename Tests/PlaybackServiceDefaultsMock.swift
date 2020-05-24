@testable
import Fosdem

final class PlaybackServiceDefaultsMock: PlaybackServiceDefaults {
    private var dictionary: [String: Any] = [:]

    func set(_ value: Any?, forKey defaultName: String) {
        dictionary[defaultName] = value
    }

    func value(forKey key: String) -> Any? {
        dictionary[key]
    }
}

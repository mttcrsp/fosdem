@testable
import Fosdem

final class DefaultsServiceMock: DefaultsService {
    private(set) var results: [String: Any] = [:]

    override func value<Value>(for key: Key<Value>) -> Value? {
        results[key.name] as? Value
    }

    override func set<Value>(_ value: Value?, for key: Key<Value>) {
        results[key.name] = value
    }
}

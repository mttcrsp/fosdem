import Foundation

class DefaultsService {
    struct Key<Value: Codable> {
        let name: String
    }

    private var defaults: UserDefaults

    init(userDefaults: UserDefaults = UserDefaults.standard) {
        defaults = userDefaults
    }

    func value<Value>(for key: Key<Value>) -> Value? {
        if isSwiftCodableType(Value.self) || isFoundationCodableType(Value.self) {
            return defaults.value(forKey: key.name) as? Value
        }

        guard let data = defaults.data(forKey: key.name) else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(Value.self, from: data)
            return decoded
        } catch {
            assertionFailure(error.localizedDescription)
        }

        return nil
    }

    func set<Value>(_ value: Value?, for key: Key<Value>) {
        if isSwiftCodableType(Value.self) || isFoundationCodableType(Value.self) {
            return defaults.set(value, forKey: key.name)
        }

        if value == nil {
            return defaults.removeObject(forKey: key.name)
        }

        do {
            let encoder = JSONEncoder()
            let encoded = try encoder.encode(value)
            defaults.set(encoded, forKey: key.name)
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

    func clear() {
        defaults.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "")
    }

    private func isSwiftCodableType<Value>(_ type: Value.Type) -> Bool {
        type is String.Type || type is Bool.Type || type is Int.Type || type is Float.Type || type is Double.Type
    }

    private func isFoundationCodableType<Value>(_ type: Value.Type) -> Bool {
        type is Date.Type
    }
}

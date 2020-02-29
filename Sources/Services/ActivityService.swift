import Foundation

protocol Activity: Codable {}

protocol ActivityServiceDefaults: AnyObject {
    func data(forKey defaultName: String) -> Data?
    func set(_ value: Any?, forKey defaultName: String)
}

extension UserDefaults: ActivityServiceDefaults {}

final class ActivityService {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let defaults: ActivityServiceDefaults

    init(defaults: ActivityServiceDefaults = UserDefaults.standard) {
        self.defaults = defaults
    }

    func register<ActivityType: Activity>(_ activity: ActivityType) {
        defaults.set(try? encoder.encode(activity), forKey: .userActivityKey)
    }

    func attemptRestoration<ActivityType: Activity>(of _: ActivityType.Type, _ restorationBlock: (ActivityType) -> Void) {
        if let data = defaults.data(forKey: .userActivityKey), let activity = try? decoder.decode(ActivityType.self, from: data) {
            restorationBlock(activity)
            defaults.set(nil, forKey: .userActivityKey)
        }
    }
}

private extension String {
    static var userActivityKey: String {
        "userActivity"
    }
}

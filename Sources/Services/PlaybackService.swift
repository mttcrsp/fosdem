import Foundation

enum PlaybackPosition: Equatable {
    case beginning
    case at(Double)
    case end
}

protocol PlaybackServiceDefaults: AnyObject {
    func value(forKey key: String) -> Any?
    func set(_ value: Any?, forKey defaultName: String)
}

extension UserDefaults: PlaybackServiceDefaults {}

final class PlaybackService {
    private var watched: Set<Int> {
        get { userDefaults.watched }
        set { userDefaults.watched = newValue }
    }

    private var watching: [String: Double] {
        get { userDefaults.watching }
        set { userDefaults.watching = newValue }
    }

    private let userDefaults: PlaybackServiceDefaults

    init(userDefaults: PlaybackServiceDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }

    func setPlaybackPosition(_ position: PlaybackPosition, forEventWithIdentifier identifier: Int) {
        switch position {
        case .beginning:
            watched.remove(identifier)
            watching.removeValue(forKey: identifier.description)
        case let .at(seconds):
            watched.remove(identifier)
            watching.updateValue(seconds, forKey: identifier.description)
        case .end:
            watched.insert(identifier)
            watching.removeValue(forKey: identifier.description)
        }
    }

    func playbackPosition(forEventWithIdentifier identifier: Int) -> PlaybackPosition {
        if watched.contains(identifier) {
            return .end
        }

        if let seconds = watching[identifier.description] {
            return .at(seconds)
        }

        return .beginning
    }
}

private extension PlaybackServiceDefaults {
    var watched: Set<Int> {
        set {
            let array = Array(newValue)
            let arrayPlist = NSArray(array: array)
            set(arrayPlist, forKey: .watched)
        }
        get {
            let object = value(forKey: .watched)
            let array = object as? [Int] ?? []
            return Set(array)
        }
    }

    var watching: [String: Double] {
        set {
            set(newValue, forKey: .watching)
        }
        get {
            let object = value(forKey: .watching)
            let dictionary = object as? [String: Double] ?? [:]
            return dictionary
        }
    }
}

private extension String {
    static var watched: String { #function }
    static var watching: String { #function }
}

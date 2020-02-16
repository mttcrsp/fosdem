import Foundation

protocol FavoritesServiceDelegate: AnyObject {
    func favoritesServiceDidUpdateTracks(_ favoritesService: FavoritesService)
    func favoritesServiceDidUpdateEvents(_ favoritesService: FavoritesService)
}

protocol FavoritesServiceDefaults: AnyObject {
    func value(forKey key: String) -> Any?
    func set(_ value: Any?, forKey defaultName: String)
}

extension UserDefaults: FavoritesServiceDefaults {}

final class FavoritesService {
    weak var delegate: FavoritesServiceDelegate?

    private let userDefaults: FavoritesServiceDefaults

    init(userDefaults: FavoritesServiceDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }

    var tracks: Set<String> {
        get { userDefaults.tracks }
        set { userDefaults.tracks = newValue }
    }

    var eventsIdentifiers: Set<String> {
        get { userDefaults.eventsIdentifiers }
        set { userDefaults.eventsIdentifiers = newValue }
    }

    func addTrack(_ track: String) {
        let (inserted, _) = tracks.insert(track)
        if inserted {
            delegate?.favoritesServiceDidUpdateTracks(self)
        }
    }

    func removeTrack(_ track: String) {
        if let _ = tracks.remove(track) {
            delegate?.favoritesServiceDidUpdateTracks(self)
        }
    }

    func addEvent(withIdentifier eventID: String) {
        let (inserted, _) = eventsIdentifiers.insert(eventID)
        if inserted {
            delegate?.favoritesServiceDidUpdateEvents(self)
        }
    }

    func removeEvent(withIdentifier eventID: String) {
        if let _ = eventsIdentifiers.remove(eventID) {
            delegate?.favoritesServiceDidUpdateEvents(self)
        }
    }
}

private extension FavoritesServiceDefaults {
    var tracks: Set<String> {
        get { value(forKey: .favoriteTracks) }
        set { set(newValue, forKey: .favoriteTracks) }
    }

    var eventsIdentifiers: Set<String> {
        get { value(forKey: .favoriteEvents) }
        set { set(newValue, forKey: .favoriteEvents) }
    }

    private func value(forKey key: String) -> Set<String> {
        let object = value(forKey: key)
        let array = object as? [String] ?? []
        return Set(array)
    }

    private func set(_ value: Set<String>, forKey defaultName: String) {
        let array = Array(value)
        let arrayPlist = NSArray(array: array)
        set(arrayPlist, forKey: defaultName)
    }
}

private extension String {
    static var favoriteTracks: String { #function }
    static var favoriteEvents: String { #function }
}

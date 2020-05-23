import Foundation

protocol FavoritesServiceDefaults: AnyObject {
    func value(forKey key: String) -> Any?
    func set(_ value: Any?, forKey defaultName: String)
}

extension UserDefaults: FavoritesServiceDefaults {}

final class FavoritesService {
    private let userDefaults: FavoritesServiceDefaults
    private let notificationCenter = NotificationCenter()

    init(userDefaults: FavoritesServiceDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }

    var tracksIdentifiers: Set<String> {
        get { userDefaults.tracksIdentifiers }
        set { userDefaults.tracksIdentifiers = newValue }
    }

    var eventsIdentifiers: Set<Int> {
        get { userDefaults.eventsIdentifiers }
        set { userDefaults.eventsIdentifiers = newValue }
    }

    func addObserverForTracks(_ handler: @escaping () -> Void) -> NSObjectProtocol {
        notificationCenter.addObserver(forName: .favoriteTracksDidChange, object: nil, queue: nil, using: { _ in handler() })
    }

    func addObserverForEvents(_ handler: @escaping () -> Void) -> NSObjectProtocol {
        notificationCenter.addObserver(forName: .favoriteEventsDidChange, object: nil, queue: nil, using: { _ in handler() })
    }

    func removeObserver(_ observer: NSObjectProtocol) {
        notificationCenter.removeObserver(observer)
    }

    func addTrack(withIdentifier trackID: String) {
        let (inserted, _) = tracksIdentifiers.insert(trackID)
        if inserted {
            notificationCenter.post(Notification(name: .favoriteTracksDidChange))
        }
    }

    func removeTrack(withIdentifier trackID: String) {
        if let _ = tracksIdentifiers.remove(trackID) {
            notificationCenter.post(Notification(name: .favoriteTracksDidChange))
        }
    }

    func contains(_ track: Track) -> Bool {
        tracksIdentifiers.contains(track.name)
    }

    func addEvent(withIdentifier eventID: Int) {
        let (inserted, _) = eventsIdentifiers.insert(eventID)
        if inserted {
            notificationCenter.post(Notification(name: .favoriteEventsDidChange))
        }
    }

    func removeEvent(withIdentifier eventID: Int) {
        if let _ = eventsIdentifiers.remove(eventID) {
            notificationCenter.post(Notification(name: .favoriteEventsDidChange))
        }
    }

    func contains(_ event: Event) -> Bool {
        eventsIdentifiers.contains(event.id)
    }
}

private extension FavoritesServiceDefaults {
    var tracksIdentifiers: Set<String> {
        get { value(forKey: .favoriteTracksKey) }
        set { set(newValue, forKey: .favoriteTracksKey) }
    }

    var eventsIdentifiers: Set<Int> {
        get { value(forKey: .favoriteEventsKey) }
        set { set(newValue, forKey: .favoriteEventsKey) }
    }

    private func value<Value: Hashable>(forKey key: String) -> Set<Value> {
        let object = value(forKey: key)
        let array = object as? [Value] ?? []
        return Set(array)
    }

    private func set<Value: Hashable>(_ value: Set<Value>, forKey defaultName: String) {
        let array = Array(value)
        let arrayPlist = NSArray(array: array)
        set(arrayPlist, forKey: defaultName)
    }
}

private extension String {
    static var favoriteTracksKey: String { #function }
    static var favoriteEventsKey: String { #function }
}

private extension Notification.Name {
    static var favoriteTracksDidChange: Notification.Name { Notification.Name(#function) }
    static var favoriteEventsDidChange: Notification.Name { Notification.Name(#function) }
}

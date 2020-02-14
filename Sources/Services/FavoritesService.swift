import Foundation

protocol FavoritesServiceDelegate: AnyObject {
    func favoritesServiceDidUpdateTracks(_ favoritesService: FavoritesService)
    func favoritesServiceDidUpdateEvents(_ favoritesService: FavoritesService)
}

final class FavoritesService {
    weak var delegate: FavoritesServiceDelegate?

    private let defaultsService: DefaultsService

    init(defaultsService: DefaultsService) {
        self.defaultsService = defaultsService
    }

    private(set) var tracks: Set<String> {
        get { defaultsService.favoriteTracks }
        set { defaultsService.favoriteTracks = newValue }
    }

    private(set) var eventsIdentifiers: Set<String> {
        get { defaultsService.favoriteEventsIdentifiers }
        set { defaultsService.favoriteEventsIdentifiers = newValue }
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

private extension DefaultsService {
    var favoriteTracks: Set<String> {
        get { value(for: .favoriteTracks) ?? [] }
        set { set(newValue, for: .favoriteTracks) }
    }

    var favoriteEventsIdentifiers: Set<String> {
        get { value(for: .favoriteEventsIdentifiers) ?? [] }
        set { set(newValue, for: .favoriteEventsIdentifiers) }
    }
}

private extension DefaultsService.Key {
    static var favoriteTracks: DefaultsService.Key<Set<String>> {
        DefaultsService.Key(name: #function)
    }

    static var favoriteEventsIdentifiers: DefaultsService.Key<Set<String>> {
        DefaultsService.Key(name: #function)
    }
}

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

    private(set) var tracks: [String] {
        get { defaultsService.favoriteTracks }
        set { defaultsService.favoriteTracks = newValue }
    }

    private var eventsIdentifiers: Set<String> {
        get { defaultsService.favoriteEventsIdentifiers }
        set { defaultsService.favoriteEventsIdentifiers = newValue }
    }

    func addTrack(_ track: String) {
        var tracks = self.tracks

        guard !tracks.contains(track) else { return }

        tracks.append(track)
        tracks.sort()
        self.tracks = tracks
        delegate?.favoritesServiceDidUpdateTracks(self)
    }

    func removeTrack(_ track: String) {
        guard let index = tracks.firstIndex(of: track) else { return }

        tracks.remove(at: index)
        delegate?.favoritesServiceDidUpdateTracks(self)
    }

    func addEvent(withIdentifier eventID: String) {
        eventsIdentifiers.insert(eventID)
        delegate?.favoritesServiceDidUpdateEvents(self)
    }

    func removeEvent(withIdentifier eventID: String) {
        eventsIdentifiers.remove(eventID)
        delegate?.favoritesServiceDidUpdateEvents(self)
    }

    func containsEvent(withIdentifier eventID: String) -> Bool {
        eventsIdentifiers.contains(eventID)
    }
}

private extension DefaultsService {
    var favoriteTracks: [String] {
        get { value(for: .favoriteTracks) ?? [] }
        set { set(newValue, for: .favoriteTracks) }
    }

    var favoriteEventsIdentifiers: Set<String> {
        get { value(for: .favoriteEventsIdentifiers) ?? [] }
        set { set(newValue, for: .favoriteEventsIdentifiers) }
    }
}

private extension DefaultsService.Key {
    static var favoriteTracks: DefaultsService.Key<[String]> {
        DefaultsService.Key(name: #function)
    }

    static var favoriteEventsIdentifiers: DefaultsService.Key<Set<String>> {
        DefaultsService.Key(name: #function)
    }
}

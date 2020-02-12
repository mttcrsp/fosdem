import Foundation

final class FavoritesService {
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

        if !tracks.contains(track) {
            tracks.append(track)
            tracks.sort()
            self.tracks = tracks
        }
    }

    func removeTrack(_ track: String) {
        tracks.removeAll { other in track == other }
    }

    func addEvent(withIdentifier eventID: String) {
        eventsIdentifiers.insert(eventID)
    }

    func removeEvent(withIdentifier eventID: String) {
        eventsIdentifiers.remove(eventID)
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

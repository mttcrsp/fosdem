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
}

private extension DefaultsService {
    var favoriteTracks: [String] {
        get { value(for: .favoriteTracks) ?? [] }
        set { set(newValue, for: .favoriteTracks) }
    }
}

private extension DefaultsService.Key {
    static var favoriteTracks: DefaultsService.Key<[String]> {
        DefaultsService.Key(name: #function)
    }
}

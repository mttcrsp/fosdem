import Foundation

protocol TracksServiceDelegate: AnyObject {
    func tracksServiceDidUpdate(_ tracksService: TracksService)
}

enum TracksFilter: Equatable, Hashable {
    case all, day(Int)
}

struct TracksSection: Equatable, Hashable {
    let title: String
    let tracks: [Track]
}

final class TracksService {
    weak var delegate: TracksServiceDelegate?

    private(set) var tracks: [Track] = []
    private(set) var filters: [TracksFilter] = []
    private(set) var favoriteTracks: [Track] = []
    private(set) var filteredTracks: [TracksFilter: [Track]] = [:]
    private var observation: NSObjectProtocol?

    private let favoritesService: FavoritesService
    private let persistenceService: PersistenceService

    init(favoritesService: FavoritesService, persistenceService: PersistenceService) {
        self.persistenceService = persistenceService
        self.favoritesService = favoritesService
    }

    func loadTracks() {
        observation = favoritesService.addObserverForTracks { [weak self] in
            self?.didChangeFavorites()
        }

        persistenceService.performRead(AllTracksOrderedByName()) { [weak self] result in
            if case let .success(tracks) = result {
                self?.didFinishLoading(with: tracks)
            }
        }
    }

    func makeSections(for filter: TracksFilter) -> [TracksSection] {
        let sectionTitle = filter.title
        let sectionTracks = filteredTracks[filter] ?? []
        let section = TracksSection(title: sectionTitle, tracks: sectionTracks)

        if favoriteTracks.isEmpty {
            return [section]
        } else {
            let favoritesTitle = NSLocalizedString("search.filter.favorites", comment: "")
            let favoritesSection = TracksSection(title: favoritesTitle, tracks: favoriteTracks)
            return [favoritesSection, section]
        }
    }

    private func didFinishLoading(with tracks: [Track]) {
        self.tracks = tracks

        favoriteTracks = []
        filteredTracks = [:]

        var filters: Set<TracksFilter> = [.all]
        for track in tracks {
            let filter = TracksFilter.day(track.day)
            filters.insert(filter)

            filteredTracks[.all, default: []].append(track)
            filteredTracks[filter, default: []].append(track)

            if favoritesService.contains(track) {
                favoriteTracks.append(track)
            }
        }

        self.filters = filters.sorted()

        delegate?.tracksServiceDidUpdate(self)
    }

    private func didChangeFavorites() {
        favoriteTracks = []
        for track in tracks where favoritesService.contains(track) {
            favoriteTracks.append(track)
        }

        delegate?.tracksServiceDidUpdate(self)
    }
}

extension TracksFilter: Comparable {
    static func < (lhs: TracksFilter, rhs: TracksFilter) -> Bool {
        switch (lhs, rhs) {
        case (.all, .all): return true
        case (.all, .day): return true
        case (.day, .all): return false
        case let (.day(lhs), .day(rhs)): return lhs < rhs
        }
    }
}

extension TracksFilter {
    var title: String {
        switch self {
        case .all:
            return NSLocalizedString("search.filter.all", comment: "")
        case let .day(day):
            let format = NSLocalizedString("search.filter.day", comment: "")
            let string = String(format: format, day)
            return string
        }
    }
}

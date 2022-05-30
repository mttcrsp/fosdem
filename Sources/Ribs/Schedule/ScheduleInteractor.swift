import Foundation
import RIBs

protocol ScheduleRouting: ViewableRouting {
  func routeToEvent(_ event: Event?)
  func routeToSearchResult(_ event: Event)
  func routeBackFromSearchResult()
}

protocol SchedulePresentable: Presentable {
  var year: Year? { get set }
  var showsFavoriteTrack: Bool { get set }
  var tracksSectionIndexTitles: [String] { get set }

  func reloadData()
  func performBatchUpdates(_ updates: () -> Void)
  func insertFavoritesSection()
  func deleteFavoritesSection()
  func insertFavorite(at index: Int)
  func deleteFavorite(at index: Int)
  func scrollToRow(at indexPath: IndexPath)

  func showError()
  func showTrack(_ track: Track, events: [Event])
  func showFilters(_ filters: [TracksFilter], selectedFilter: TracksFilter)
}

final class ScheduleInteractor: PresentableInteractor<SchedulePresentable>, ScheduleInteractable {
  weak var router: ScheduleRouting?

  private var observer: NSObjectProtocol?
  private var selectedFilter: TracksFilter = .all
  private var selectedTrack: Track?

  private let dependency: ScheduleDependency

  init(presenter: SchedulePresentable, dependency: ScheduleDependency) {
    self.dependency = dependency
    super.init(presenter: presenter)
  }

  override func didBecomeActive() {
    super.didBecomeActive()

    presenter.year = type(of: dependency.yearsService).current

    dependency.tracksService.delegate = self
    dependency.tracksService.loadTracks()

    observer = dependency.favoritesService.addObserverForTracks { [weak self] _ in
      if let self = self, let track = self.selectedTrack {
        self.presenter.showsFavoriteTrack = self.dependency.favoritesService.contains(track)
      }
    }
  }

  override func willResignActive() {
    super.willResignActive()

    if let observer = observer {
      dependency.favoritesService.removeObserver(observer)
    }
  }

  func didSelectResult(_ event: Event) {
    router?.routeToSearchResult(event)
  }
}

extension ScheduleInteractor: SchedulePresentableListener {
  func canFavorite(_ event: Event) -> Bool {
    !dependency.favoritesService.contains(event)
  }

  func canFavorite(_ track: Track) -> Bool {
    !dependency.favoritesService.contains(track)
  }

  func toggleFavorite(_ event: Event) {
    if canFavorite(event) {
    } else {
      dependency.favoritesService.removeEvent(withIdentifier: event.id)
    }
  }

  func toggleFavorite(_ track: Track?) {
    guard let track = track ?? selectedTrack else { return }

    if canFavorite(track) {
      dependency.favoritesService.addTrack(withIdentifier: track.name)
    } else {
      dependency.favoritesService.removeTrack(withIdentifier: track.name)
    }
  }

  func selectFilters() {
    presenter.showFilters(dependency.tracksService.filters, selectedFilter: selectedFilter)
  }

  func select(_ event: Event) {
    router?.routeToEvent(event)
  }

  func select(_ selectedFilter: TracksFilter) {
    self.selectedFilter = selectedFilter
    presenter.reloadData()
  }

  func select(_ selectedTrack: Track) {
    self.selectedTrack = selectedTrack

    let operation = EventsForTrack(track: selectedTrack.name)
    dependency.persistenceService.performRead(operation) { [weak self] result in
      DispatchQueue.main.async {
        guard let self = self else { return }

        switch result {
        case .failure:
          self.presenter.showError()
        case let .success(events):
          self.presenter.showTrack(selectedTrack, events: events)
          self.presenter.showsFavoriteTrack = self.dependency.favoritesService.contains(selectedTrack)
        }
      }
    }
  }

  func selectTracksSection(_ section: String) {
    if let index = dependency.tracksService.filteredIndexTitles[selectedFilter]?[section] {
      let indexPath = IndexPath(row: index, section: hasFavoriteTracks ? 1 : 0)
      presenter.scrollToRow(at: indexPath)
    }
  }

  func deselectEvent() {
    router?.routeToEvent(nil)
  }

  func deselectSearchResult() {
    router?.routeBackFromSearchResult()
  }
}

extension ScheduleInteractor: TracksServiceDelegate {
  func tracksServiceDidUpdateTracks(_: TracksService) {
    presenter.tracksSectionIndexTitles = filteredTracksSectionIndexTitles
    presenter.reloadData()
  }

  func tracksService(_: TracksService, performBatchUpdates updates: () -> Void) {
    presenter.tracksSectionIndexTitles = filteredTracksSectionIndexTitles
    presenter.performBatchUpdates(updates)
  }

  func tracksService(_: TracksService, insertFavoriteWith identifier: String) {
    if filteredFavoriteTracks.count == 1 {
      presenter.insertFavoritesSection()
    } else if let index = filteredFavoriteTracks.firstIndex(where: { track in track.name == identifier }) {
      presenter.insertFavorite(at: index)
    }
  }

  func tracksService(_: TracksService, deleteFavoriteWith identifier: String) {
    if filteredFavoriteTracks.count == 1 {
      presenter.deleteFavoritesSection()
    } else if let index = filteredFavoriteTracks.firstIndex(where: { track in track.name == identifier }) {
      presenter.deleteFavorite(at: index)
    }
  }

  private func isFavoriteSection(_ section: Int) -> Bool {
    section == 0 && hasFavoriteTracks
  }

  private var hasFavoriteTracks: Bool {
    !filteredFavoriteTracks.isEmpty
  }

  var tracksSections: [TracksSection] {
    var sections: [TracksSection] = []

    if hasFavoriteTracks {
      let sectionTitle = L10n.Search.Filter.favorites
      let sectionAccessibilityIdentifier = "favorites"
      let sectionTracks = filteredFavoriteTracks
      sections.append(TracksSection(title: sectionTitle, accessibilityIdentifier: sectionAccessibilityIdentifier, tracks: sectionTracks))
    }

    let sectionTitle = selectedFilter.title
    let sectionAccessibilityIdentifier = selectedFilter.accessibilityIdentifier
    let sectionTracks = filteredTracks
    sections.append(TracksSection(title: sectionTitle, accessibilityIdentifier: sectionAccessibilityIdentifier, tracks: sectionTracks))

    return sections
  }

  private var filteredTracks: [Track] {
    dependency.tracksService.filteredTracks[selectedFilter] ?? []
  }

  private var filteredFavoriteTracks: [Track] {
    dependency.tracksService.filteredFavoriteTracks[selectedFilter] ?? []
  }

  private var filteredTracksSectionIndexTitles: [String] {
    dependency.tracksService.filteredIndexTitles[selectedFilter]?.keys.sorted() ?? []
  }
}

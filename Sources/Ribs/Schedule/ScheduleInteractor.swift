import Foundation
import RIBs

protocol ScheduleRouting: ViewableRouting {
  func attachSearch(_ arguments: SearchArguments)
  func routeToTrack(_ track: Track?)
  func routeToSearchResult(_ event: Event)
  func routeBackFromSearchResult()
}

protocol SchedulePresentable: Presentable {
  var year: Year? { get set }
  var tracksSectionIndexTitles: [String] { get set }

  func reloadData()
  func performBatchUpdates(_ updates: () -> Void)
  func insertFavoritesSection()
  func deleteFavoritesSection()
  func insertFavorite(at index: Int)
  func deleteFavorite(at index: Int)
  func scrollToRow(at indexPath: IndexPath)

  func showError()
  func showWelcome()
  func showFilters(_ filters: [TracksFilter], selectedFilter: TracksFilter)
}

final class ScheduleInteractor: PresentableInteractor<SchedulePresentable> {
  weak var router: ScheduleRouting?

  private var selectedFilter: TracksFilter = .all
  private var selectedTrack: Track?

  private let component: ScheduleComponent

  init(component: ScheduleComponent, presenter: SchedulePresentable) {
    self.component = component
    super.init(presenter: presenter)
  }

  override func didBecomeActive() {
    super.didBecomeActive()

    let arguments = SearchArguments(
      persistenceService: component.persistenceService,
      favoritesService: component.favoritesService
    )

    router?.attachSearch(arguments)
    presenter.year = type(of: component.yearsService).current
    component.tracksService.delegate = self
    component.tracksService.loadTracks()
  }
}

extension ScheduleInteractor: SchedulePresentableListener {
  func canFavorite(_ track: Track) -> Bool {
    component.favoritesService.canFavorite(track)
  }

  func toggleFavorite(_ track: Track) {
    component.favoritesService.toggleFavorite(track)
  }

  func selectFilters() {
    presenter.showFilters(component.tracksService.filters, selectedFilter: selectedFilter)
  }

  func select(_ selectedFilter: TracksFilter) {
    self.selectedFilter = selectedFilter
    presenter.reloadData()
  }

  func select(_ track: Track?) {
    router?.routeToTrack(track)
  }

  func selectTracksSection(_ section: String) {
    if let index = component.tracksService.filteredIndexTitles[selectedFilter]?[section] {
      let indexPath = IndexPath(row: index, section: hasFavoriteTracks ? 1 : 0)
      presenter.scrollToRow(at: indexPath)
    }
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
    component.tracksService.filteredTracks[selectedFilter] ?? []
  }

  private var filteredFavoriteTracks: [Track] {
    component.tracksService.filteredFavoriteTracks[selectedFilter] ?? []
  }

  private var filteredTracksSectionIndexTitles: [String] {
    component.tracksService.filteredIndexTitles[selectedFilter]?.keys.sorted() ?? []
  }
}

extension ScheduleInteractor: ScheduleInteractable {
  func didSelectResult(_ event: Event) {
    router?.routeToSearchResult(event)
  }

  func trackDidError(_: Error) {
    presenter.showError()
    presenter.showWelcome()
  }
}

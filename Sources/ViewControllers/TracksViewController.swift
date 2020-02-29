import UIKit

protocol TracksViewControllerDataSource: AnyObject {
    var tracks: [Track] { get }
    var tracksForDay: [[Track]] { get }
    var favoriteTracks: [Track] { get }
}

protocol TracksViewControllerDelegate: AnyObject {
    func tracksViewController(_ tracksViewController: TracksViewController, didSelect track: Track)
    func tracksViewController(_ tracksViewController: TracksViewController, didFavorite track: Track)
    func tracksViewController(_ tracksViewController: TracksViewController, didUnfavorite track: Track)
}

final class TracksViewController: UITableViewController {
    weak var dataSource: TracksViewControllerDataSource?
    weak var delegate: TracksViewControllerDelegate?

    fileprivate enum Filter {
        case all, favorites, day(Int)
    }

    var selectedTrack: Track? {
        tableView.indexPathForSelectedRow.map(track)
    }

    private var tracks: [Track] {
        dataSource?.tracks ?? []
    }

    private var tracksByDay: [[Track]] {
        dataSource?.tracksForDay ?? []
    }

    private var favoriteTracks: [Track] {
        dataSource?.favoriteTracks ?? []
    }

    private var filteredTracks: [Track] {
        switch selectedFilter {
        case .none, .all:
            return tracks
        case .favorites:
            return favoriteTracks
        case let .day(number):
            return tracksByDay[number - 1]
        }
    }

    private var selectedFilter: Filter? {
        if let selectedIndex = filtersView.selectedSegmentIndex {
            return filters[selectedIndex]
        } else {
            return nil
        }
    }

    private lazy var filtersView = SegmentedTableViewHeaderFooterView()
    private lazy var filters: [Filter] = makeFilters()

    func reloadData() {
        filters = makeFilters()
        filtersView.setSegments(for: filters)
        tableView.reloadData()
    }

    func reloadFavorites() {
        if case .some(.favorites) = selectedFilter {
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
        filtersView.addTarget(self, action: #selector(didSelectFilter), for: .valueChanged)
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        filteredTracks.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
        cell.configure(with: track(at: indexPath))
        return cell
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.tracksViewController(self, didSelect: track(at: indexPath))
    }

    override func tableView(_: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if favoriteTracks.contains(track(at: indexPath)) {
            return [.unfavorite { [weak self] indexPath in self?.didUnfavoriteTrack(at: indexPath) }]
        } else {
            return [.favorite { [weak self] indexPath in self?.didFavoriteTrack(at: indexPath) }]
        }
    }

    override func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? {
        filtersView
    }

    private func didFavoriteTrack(at indexPath: IndexPath) {
        delegate?.tracksViewController(self, didFavorite: track(at: indexPath))
    }

    private func didUnfavoriteTrack(at indexPath: IndexPath) {
        delegate?.tracksViewController(self, didUnfavorite: track(at: indexPath))
    }

    @objc private func didSelectFilter() {
        tableView.reloadData()
    }

    private func makeFilters() -> [Filter] {
        var filters: [Filter] = []
        filters.append(.all)

        for index in tracksByDay.indices {
            filters.append(.day(index + 1))
        }

        filters.append(.favorites)
        return filters
    }

    private func track(at indexPath: IndexPath) -> Track {
        filteredTracks[indexPath.row]
    }
}

private extension TracksViewController.Filter {
    var title: String {
        switch self {
        case .all:
            return NSLocalizedString("tracks.filter.all", comment: "")
        case .favorites:
            return NSLocalizedString("tracks.filter.favorites", comment: "")
        case let .day(day):
            return String(format: NSLocalizedString("tracks.filter.day", comment: ""), day)
        }
    }
}

private extension UITableViewCell {
    func configure(with track: Track) {
        textLabel?.text = track.name
        accessoryType = .disclosureIndicator
    }
}

private extension SegmentedTableViewHeaderFooterView {
    func setSegments(for filters: [TracksViewController.Filter]) {
        removeAllSegments()

        for (index, filter) in filters.enumerated() {
            insertSegment(withTitle: filter.title, at: index, animated: false)
        }

        if selectedSegmentIndex == nil, !filters.isEmpty {
            selectedSegmentIndex = 0
        }
    }
}

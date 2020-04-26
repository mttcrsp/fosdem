import UIKit

protocol TracksViewControllerDataSource: AnyObject {
    func tracks(in tracksViewController: TracksViewController) -> [Track]
    func favoriteTracks(in tracksViewController: TracksViewController) -> [Track]
}

protocol TracksViewControllerFavoritesDataSource: AnyObject {
    func tracksViewController(_ tracksViewController: TracksViewController, canFavorite track: Track) -> Bool
}

protocol TracksViewControllerDelegate: AnyObject {
    func tracksViewController(_ tracksViewController: TracksViewController, didSelect track: Track)
}

protocol TracksViewControllerFavoritesDelegate: AnyObject {
    func tracksViewController(_ tracksViewController: TracksViewController, didFavorite track: Track)
    func tracksViewController(_ tracksViewController: TracksViewController, didUnfavorite track: Track)
}

final class TracksViewController: UITableViewController {
    struct Section {
        var title: String?
        var items: [Item]
    }

    struct Item {
        var track: Track
        var roundsTopCorners = false
        var roundsBottomCorners = false
    }

    weak var dataSource: TracksViewControllerDataSource?
    weak var delegate: TracksViewControllerDelegate?

    weak var favoritesDataSource: TracksViewControllerFavoritesDataSource?
    weak var favoritesDelegate: TracksViewControllerFavoritesDelegate?

    private var sectionForSectionIndexTitle: [String: Int] = [:]
    private var sectionIndexTitles: [String] = []
    private var sections: [Section] = []

    var selectedTrack: Track? {
        if let indexPath = tableView.indexPathForSelectedRow {
            return track(at: indexPath)
        } else {
            return nil
        }
    }

    func reloadData() {
        if isViewLoaded {
            tableView.reloadData()
            reloadDataStructures()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .fos_systemGroupedBackground
        tableView.register(TrackTableViewCell.self, forCellReuseIdentifier: TrackTableViewCell.reuseIdentifier)
        reloadDataStructures()
    }

    override func numberOfSections(in _: UITableView) -> Int {
        sections.count
    }

    override func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? {
        UIView()
    }

    override func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        0
    }

    override func sectionIndexTitles(for _: UITableView) -> [String]? {
        sectionIndexTitles
    }

    override func tableView(_: UITableView, sectionForSectionIndexTitle title: String, at _: Int) -> Int {
        sectionForSectionIndexTitle[title] ?? 0
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.item(at: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: TrackTableViewCell.reuseIdentifier, for: indexPath) as! TrackTableViewCell
        cell.configure(with: item.track)
        cell.roundsTopCorners = item.roundsTopCorners
        cell.roundsBottomCorners = item.roundsBottomCorners
        return cell
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.tracksViewController(self, didSelect: track(at: indexPath))
    }

    override func tableView(_: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard let favoritesDataSource = favoritesDataSource else { return nil }

        let track = self.track(at: indexPath)

        if favoritesDataSource.tracksViewController(self, canFavorite: track) {
            return [.favorite { [weak self] _ in self?.didFavoriteTrack(track) }]
        } else {
            return [.unfavorite { [weak self] _ in self?.didUnfavoriteTrack(track) }]
        }
    }

    private func didFavoriteTrack(_ track: Track) {
        favoritesDelegate?.tracksViewController(self, didFavorite: track)
    }

    private func didUnfavoriteTrack(_ track: Track) {
        favoritesDelegate?.tracksViewController(self, didUnfavorite: track)
    }

    private func item(at indexPath: IndexPath) -> Item {
        sections[indexPath.section].items[indexPath.row]
    }

    private func track(at indexPath: IndexPath) -> Track {
        item(at: indexPath).track
    }

    private func reloadDataStructures() {
        sections = makeSections()

        let indices = makeSectionIndexTitles(from: sections)
        sectionIndexTitles = indices.sectionIndexTitles
        sectionForSectionIndexTitle = indices.sectionForSectionIndexTitle
    }

    private func makeSectionIndexTitles(from sections: [Section]) -> (sectionIndexTitles: [String], sectionForSectionIndexTitle: [String: Int]) {
        var sectionForSectionIndexTitle: [String: Int] = [:]
        var sectionIndexTitles: [String] = []

        for (index, section) in sections.enumerated() {
            if let title = section.title {
                sectionIndexTitles.append(title)
                sectionForSectionIndexTitle[title] = index
            }
        }

        return (sectionIndexTitles, sectionForSectionIndexTitle)
    }

    private func makeSections() -> [Section] {
        guard let dataSource = dataSource else { return [] }

        var sections: [Section] = []

        let favoriteTracks = dataSource.favoriteTracks(in: self)
        if let section = makeFavoritesSection(with: favoriteTracks) {
            sections.append(section)
        }

        let standardTracks = dataSource.tracks(in: self)
        let standardSections = makeStandardSections(with: standardTracks)
        sections.append(contentsOf: standardSections)

        return sections
    }

    private func makeFavoritesSection(with tracks: [Track]) -> Section? {
        guard !tracks.isEmpty else {
            return nil
        }

        var items: [Item] = []
        for track in tracks {
            items.append(Item(track: track))
        }

        items[0].roundsTopCorners = true
        items[tracks.count - 1].roundsBottomCorners = true
        return Section(title: nil, items: items)
    }

    private func makeStandardSections(with tracks: [Track]) -> [Section] {
        guard !tracks.isEmpty else {
            return []
        }

        var tracksForInitial: [Character: [Track]] = [:]
        for track in tracks {
            if let initial = track.name.first {
                tracksForInitial[initial, default: []].append(track)
            }
        }

        let sortedTracksForInitial = tracksForInitial.sorted(by: { lhs, rhs in lhs.key < rhs.key })

        var sections: [Section] = []
        for (initial, tracks) in sortedTracksForInitial {
            var section = Section(title: String(initial), items: [])
            for track in tracks {
                section.items.append(Item(track: track))
            }
            sections.append(section)
        }

        if !sections.isEmpty {
            sections[0].items[0].roundsTopCorners = true
            sections[sections.count - 1].items[sections[sections.count - 1].items.count - 1].roundsBottomCorners = true
        }

        return sections
    }
}

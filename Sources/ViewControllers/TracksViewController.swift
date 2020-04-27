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
    weak var dataSource: TracksViewControllerDataSource?
    weak var delegate: TracksViewControllerDelegate?

    weak var favoritesDataSource: TracksViewControllerFavoritesDataSource?
    weak var favoritesDelegate: TracksViewControllerFavoritesDelegate?

    var selectedTrack: Track? {
        if let indexPath = tableView.indexPathForSelectedRow {
            return track(at: indexPath)
        } else {
            return nil
        }
    }

    func reloadTracks() {
        if isViewLoaded {
            tableView.reloadData()
            reloadDataStructures()
        }
    }

    func reloadFavoriteTracks() {
        reloadTracks()
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
}

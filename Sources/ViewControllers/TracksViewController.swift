import UIKit

protocol TracksViewControllerDataSource: AnyObject {
    func sections(in tracksViewController: TracksViewController) -> [TracksSection]
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

    private var sections: [TracksSection] = []

    var selectedTrack: Track? {
        if let indexPath = tableView.indexPathForSelectedRow {
            return dataSource?.tracksViewController(self, trackAt: indexPath)
        } else {
            return nil
        }
    }

    func reloadData() {
        if isViewLoaded {
            tableView.reloadData()
        }
    }

    func reloadFavoritesData() {
        reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
    }

    override func numberOfSections(in _: UITableView) -> Int {
        dataSource?.sections(in: self).count ?? 0
    }

    override func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        dataSource?.tracksViewController(self, sectionAt: section).title
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSource?.tracksViewController(self, sectionAt: section).tracks.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
        if let track = dataSource?.tracksViewController(self, trackAt: indexPath) {
            cell.configure(with: track)
        }
        return cell
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let track = dataSource?.tracksViewController(self, trackAt: indexPath) {
            delegate?.tracksViewController(self, didSelect: track)
        }
    }

    override func tableView(_: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard let dataSource = dataSource, let favoritesDataSource = favoritesDataSource else { return nil }

        let track = dataSource.tracksViewController(self, trackAt: indexPath)

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
}

private extension TracksViewControllerDataSource {
    func tracksViewController(_ tracksViewController: TracksViewController, sectionAt index: Int) -> TracksSection {
        sections(in: tracksViewController)[index]
    }

    func tracksViewController(_ tracksViewController: TracksViewController, trackAt indexPath: IndexPath) -> Track {
        sections(in: tracksViewController)[indexPath.section].tracks[indexPath.row]
    }
}

private extension UITableViewCell {
    func configure(with track: Track) {
        textLabel?.text = track.name
        accessoryType = .disclosureIndicator
    }
}

import UIKit

protocol TracksViewControllerDataSource: AnyObject {
    func numberOfSections(in tracksViewController: TracksViewController) -> Int
    func sectionIndexTitles(for tracksViewController: TracksViewController) -> [String]?
    func tracksViewController(_ tracksViewController: TracksViewController, numberOfTracksIn section: Int) -> Int
    func tracksViewController(_ tracksViewController: TracksViewController, trackAt indexPath: IndexPath) -> Track
    func tracksViewController(_ tracksViewController: TracksViewController, canFavoriteTrackAt indexPath: IndexPath) -> Bool
}

protocol TracksViewControllerDelegate: AnyObject {
    func tracksViewController(_ tracksViewController: TracksViewController, didSelect track: Track)
    func tracksViewController(_ tracksViewController: TracksViewController, didFavorite track: Track)
    func tracksViewController(_ tracksViewController: TracksViewController, didUnfavorite track: Track)
}

final class TracksViewController: UITableViewController {
    weak var dataSource: TracksViewControllerDataSource?
    weak var delegate: TracksViewControllerDelegate?

    private lazy var tableBackgroundView = TableBackgroundView()

    var selectedTrack: Track? {
        if let indexPath = tableView.indexPathForSelectedRow {
            return dataSource?.tracksViewController(self, trackAt: indexPath)
        } else {
            return nil
        }
    }

    func reloadData() {
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
        tableBackgroundView.text = NSLocalizedString("tracks.empty", comment: "")
    }

    override func numberOfSections(in _: UITableView) -> Int {
        let count = dataSource?.numberOfSections(in: self) ?? 0
        tableView.backgroundView = count == 0 ? tableBackgroundView : nil
        return count
    }

    override func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? {
        .init()
    }

    override func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        0
    }

    override func sectionIndexTitles(for _: UITableView) -> [String]? {
        dataSource?.sectionIndexTitles(for: self)
    }

    override func tableView(_: UITableView, sectionForSectionIndexTitle _: String, at index: Int) -> Int {
        index
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSource?.tracksViewController(self, numberOfTracksIn: section) ?? 0
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
        if dataSource?.tracksViewController(self, canFavoriteTrackAt: indexPath) == true {
            return [.favorite { [weak self] indexPath in self?.didFavoriteTrack(at: indexPath) }]
        } else {
            return [.unfavorite { [weak self] indexPath in self?.didUnfavoriteTrack(at: indexPath) }]
        }
    }

    private func didFavoriteTrack(at indexPath: IndexPath) {
        if let track = dataSource?.tracksViewController(self, trackAt: indexPath) {
            delegate?.tracksViewController(self, didFavorite: track)
        }
    }

    private func didUnfavoriteTrack(at indexPath: IndexPath) {
        if let track = dataSource?.tracksViewController(self, trackAt: indexPath) {
            delegate?.tracksViewController(self, didUnfavorite: track)
        }
    }
}

private extension UITableViewCell {
    func configure(with track: Track) {
        textLabel?.text = track.name
        accessoryType = .disclosureIndicator
    }
}

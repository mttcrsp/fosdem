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

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        0
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
        favoriteTracks.contains(track(at: indexPath)) ?
            [.unfavorite { [weak self] indexPath in self?.unfavoriteTapped(at: indexPath) }] :
            [.favorite { [weak self] indexPath in self?.favoriteTapped(at: indexPath) }]
    }

    private func favoriteTapped(at indexPath: IndexPath) {
        delegate?.tracksViewController(self, didFavorite: track(at: indexPath))
    }

    private func unfavoriteTapped(at indexPath: IndexPath) {
        delegate?.tracksViewController(self, didUnfavorite: track(at: indexPath))
    }

    func reloadData() {
        tableView.reloadData()
    }

    func reloadFavorites() {
        reloadData()
    }

    private func track(at _: IndexPath) -> Track {
        fatalError()
    }
}

private extension UITableViewCell {
    func configure(with track: Track) {
        textLabel?.text = track.name
        accessoryType = .disclosureIndicator
    }
}

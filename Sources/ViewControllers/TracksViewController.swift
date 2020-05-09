import UIKit

protocol TracksViewControllerDataSource: AnyObject {
    func numberOfSections(in tracksViewController: TracksViewController) -> Int
    func tracksViewController(_ tracksViewController: TracksViewController, titleForSectionAt section: Int) -> String?
    func tracksViewController(_ tracksViewController: TracksViewController, numberOfTracksIn section: Int) -> Int
    func tracksViewController(_ tracksViewController: TracksViewController, trackAt indexPath: IndexPath) -> Track
}

protocol TracksViewControllerIndexDataSource: AnyObject {
    func sectionIndexTitles(in tracksViewController: TracksViewController) -> [String]
}

protocol TracksViewControllerFavoritesDataSource: AnyObject {
    func tracksViewController(_ tracksViewController: TracksViewController, canFavorite track: Track) -> Bool
}

protocol TracksViewControllerDelegate: AnyObject {
    func tracksViewController(_ tracksViewController: TracksViewController, didSelect track: Track)
}

protocol TracksViewControllerIndexDelegate: AnyObject {
    func tracksViewController(_ tracksViewController: TracksViewController, didSelect section: Int)
}

protocol TracksViewControllerFavoritesDelegate: AnyObject {
    func tracksViewController(_ tracksViewController: TracksViewController, didFavorite track: Track)
    func tracksViewController(_ tracksViewController: TracksViewController, didUnfavorite track: Track)
}

final class TracksViewController: UITableViewController {
    weak var dataSource: TracksViewControllerDataSource?
    weak var delegate: TracksViewControllerDelegate?

    weak var indexDataSource: TracksViewControllerIndexDataSource?
    weak var indexDelegate: TracksViewControllerIndexDelegate?

    weak var favoritesDataSource: TracksViewControllerFavoritesDataSource?
    weak var favoritesDelegate: TracksViewControllerFavoritesDelegate?

    private lazy var backgroundView = TracksBackgroundView()

    func reloadData() {
        if isViewLoaded {
            tableView.reloadData()
            backgroundView.sectionTitles = indexDataSource?.sectionIndexTitles(in: self) ?? []
        }
    }

    func scrollToRow(at indexPath: IndexPath, at scrollPosition: UITableView.ScrollPosition, animated: Bool) {
        tableView.scrollToRow(at: indexPath, at: scrollPosition, animated: animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        backgroundView.delegate = self
        backgroundView.sectionTitles = indexDataSource?.sectionIndexTitles(in: self) ?? []

        tableView.tableFooterView = UIView()
        tableView.backgroundView = backgroundView
        tableView.showsVerticalScrollIndicator = indexDataSource == nil
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
        tableView.register(LabelTableHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: LabelTableHeaderFooterView.reuseIdentifier)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundView.isHidden = traitCollection.userInterfaceIdiom == .pad || view.bounds.width > view.bounds.height
    }

    override func numberOfSections(in _: UITableView) -> Int {
        dataSource?.numberOfSections(in: self) ?? 0
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: LabelTableHeaderFooterView.reuseIdentifier) as! LabelTableHeaderFooterView
        view.text = dataSource?.tracksViewController(self, titleForSectionAt: section)
        view.font = .fos_preferredFont(forTextStyle: .headline)
        view.textColor = .fos_label
        return view
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

extension TracksViewController: TracksBackgroundViewDelegate {
    func backgroundView(_: TracksBackgroundView, didSelect section: Int) {
        indexDelegate?.tracksViewController(self, didSelect: section)
    }
}

private extension UITableViewCell {
    func configure(with track: Track) {
        textLabel?.numberOfLines = 0
        textLabel?.text = track.name
        accessoryType = .disclosureIndicator
    }
}

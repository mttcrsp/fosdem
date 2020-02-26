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

    var sorting: Sorting = .alphabetical {
        didSet { sortingChanged() }
    }

    var selectedTrack: Track? {
        tableView.indexPathForSelectedRow.map(track)
    }

    enum Sorting {
        case alphabetical, byDay
    }

    private struct Section {
        let type: SectionType, tracks: [Track]
    }

    fileprivate enum SectionType: Equatable {
        case all, favorites, day(Int)
    }

    private var sections: [Section] = []

    private var tracks: [Track] {
        dataSource?.tracks ?? []
    }

    private var tracksByDay: [[Track]] {
        dataSource?.tracksForDay ?? []
    }

    private var favoriteTracks: [Track] {
        dataSource?.favoriteTracks ?? []
    }

    private lazy var sortingButton: UIBarButtonItem = {
        let sortingTitle = sorting.next.title
        let sortingAction = #selector(sortingTapped)
        return UIBarButtonItem(title: sortingTitle, style: .plain, target: self, action: sortingAction)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        sections = makeSections()
        navigationItem.rightBarButtonItem = sortingButton
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
    }

    override func numberOfSections(in _: UITableView) -> Int {
        sections.count
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        tracks(forSection: section).count
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

    override func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].type.title
    }

    override func tableView(_: UITableView, willDisplayHeaderView view: UIView, forSection _: Int) {
        guard let view = view as? UITableViewHeaderFooterView else { return }
        view.textLabel?.font = .preferredFont(forTextStyle: .headline)
    }

    @objc private func sortingTapped() {
        sorting = sorting.next
    }

    func reloadData() {
        sections = makeSections()
        tableView.reloadData()
    }

    func reloadFavorites() {
        reloadData()
    }

    private func sortingChanged() {
        reloadData()
        sortingButton.title = sorting.next.title
    }

    private func tracks(forSection section: Int) -> [Track] {
        sections[section].tracks
    }

    private func track(at indexPath: IndexPath) -> Track {
        tracks(forSection: indexPath.section)[indexPath.row]
    }

    private func makeSections() -> [Section] {
        var sections: [Section] = [.init(type: .favorites, tracks: favoriteTracks)]

        switch sorting {
        case .alphabetical:
            sections.append(.init(type: .all, tracks: tracks))
        case .byDay:
            sections.append(contentsOf: tracksByDay.enumerated().map { i, tracks in
                .init(type: .day(i + 1), tracks: tracks)
            })
        }

        return sections
    }
}

private extension TracksViewController.SectionType {
    var title: String {
        switch self {
        case .all:
            return NSLocalizedString("tracks.section.all", comment: "")
        case .favorites:
            return NSLocalizedString("tracks.section.favorites", comment: "")
        case let .day(day):
            let format = NSLocalizedString("tracks.section.day", comment: "")
            return String(format: format, day)
        }
    }
}

private extension TracksViewController.Sorting {
    var next: TracksViewController.Sorting {
        switch self {
        case .alphabetical: return .byDay
        case .byDay: return .alphabetical
        }
    }

    var title: String {
        switch self {
        case .byDay: return NSLocalizedString("tracks.sorting.day", comment: "")
        case .alphabetical: return NSLocalizedString("tracks.sorting.alphabet", comment: "")
        }
    }
}

private extension UITableViewCell {
    func configure(with track: Track) {
        textLabel?.text = track.name
        accessoryType = .disclosureIndicator
    }
}

extension UITableViewCell {
    static var reuseIdentifier: String {
        .init(describing: self)
    }
}

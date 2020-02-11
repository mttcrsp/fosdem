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

    init() {
        if #available(iOS 13.0, *) {
            super.init(style: .insetGrouped)
        } else {
            super.init(style: .grouped)
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
            [makeUnfavoriteAction(for: indexPath)] :
            [makeFavoriteAction(for: indexPath)]
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

    private func makeFavoriteAction(for indexPath: IndexPath) -> UITableViewRowAction {
        let action = UITableViewRowAction(style: .normal, title: NSLocalizedString("Favorite", comment: "")) { [weak self] _, indexPath in
            if let self = self { self.delegate?.tracksViewController(self, didFavorite: self.track(at: indexPath)) }
        }
        action.backgroundColor = .systemBlue
        return action
    }

    private func makeUnfavoriteAction(for indexPath: IndexPath) -> UITableViewRowAction {
        .init(style: .destructive, title: NSLocalizedString("Unfavorite", comment: "")) { [weak self] _, indexPath in
            if let self = self { self.delegate?.tracksViewController(self, didUnfavorite: self.track(at: indexPath)) }
        }
    }
}

private extension TracksViewController.SectionType {
    var title: String {
        switch self {
        case .favorites: return NSLocalizedString("Favorite tracks", comment: "")
        case let .day(day): return NSLocalizedString("Day \(day)", comment: "")
        case .all: return NSLocalizedString("All tracks", comment: "")
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
        case .byDay: return NSLocalizedString("By day", comment: "")
        case .alphabetical: return NSLocalizedString("Alphabetical", comment: "")
        }
    }
}

private extension UITableViewCell {
    func configure(with track: Track) {
        textLabel?.text = track
        accessoryType = .disclosureIndicator
    }
}

extension UITableViewCell {
    static var reuseIdentifier: String {
        .init(describing: self)
    }
}

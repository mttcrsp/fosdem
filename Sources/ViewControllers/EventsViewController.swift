import UIKit

protocol EventsViewControllerDataSource: AnyObject {
    func events(in eventsViewController: EventsViewController) -> [Event]
    func eventsViewController(_ eventsViewController: EventsViewController, captionFor event: Event) -> String?
}

protocol EventsViewControllerLiveDataSource: AnyObject {
    func eventsViewController(_ eventsViewController: EventsViewController, shouldShowLiveIndicatorFor event: Event) -> Bool
}

protocol EventsViewControllerFavoritesDataSource: AnyObject {
    func eventsViewController(_ eventsViewController: EventsViewController, canFavorite event: Event) -> Bool
}

protocol EventsViewControllerDelegate: AnyObject {
    func eventsViewController(_ eventsViewController: EventsViewController, didSelect event: Event)
}

protocol EventsViewControllerFavoritesDelegate: AnyObject {
    func eventsViewController(_ eventsViewController: EventsViewController, didFavorite event: Event)
    func eventsViewController(_ eventsViewController: EventsViewController, didUnfavorite event: Event)
}

final class EventsViewController: UITableViewController {
    weak var dataSource: EventsViewControllerDataSource?
    weak var delegate: EventsViewControllerDelegate?

    weak var favoritesDataSource: EventsViewControllerFavoritesDataSource?
    weak var favoritesDelegate: EventsViewControllerFavoritesDelegate?

    weak var liveDataSource: EventsViewControllerLiveDataSource?

    var emptyBackgroundText: String? {
        get { emptyBackgroundView.text }
        set { emptyBackgroundView.text = newValue }
    }

    private lazy var emptyBackgroundView = TableBackgroundView()

    private var events: [Event] {
        dataSource?.events(in: self) ?? []
    }

    func reloadData() {
        if isViewLoaded {
            tableView.reloadData()
        }
    }

    func reloadLiveStatus() {
        guard isViewLoaded else { return }

        var indexPaths: [IndexPath] = []

        for indexPath in tableView.indexPathsForVisibleRows ?? [] {
            if let cell = tableView.cellForRow(at: indexPath) {
                let event = self.event(for: indexPath.section)
                let oldStatus = cell.showsLiveIndicator
                let newStatus = shouldShowLiveIndicator(for: event)

                if oldStatus != newStatus {
                    indexPaths.append(indexPath)
                }
            }
        }

        tableView.reloadRows(at: indexPaths, with: .fade)
    }

    func select(_ event: Event) {
        if let row = events.firstIndex(of: event) {
            let indexPath = IndexPath(row: row, section: 0)
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
        tableView.register(LabelTableHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: LabelTableHeaderFooterView.reuseIdentifier)
    }

    override func numberOfSections(in _: UITableView) -> Int {
        let count = events.count
        tableView.backgroundView = count == 0 ? emptyBackgroundView : nil
        return count
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: LabelTableHeaderFooterView.reuseIdentifier) as! LabelTableHeaderFooterView
        view.text = dataSource?.eventsViewController(self, captionFor: event(for: section))
        return view
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let event = self.event(for: indexPath.section)
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
        cell.showsLiveIndicator = shouldShowLiveIndicator(for: event)
        cell.configure(with: event)
        return cell
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.eventsViewController(self, didSelect: event(for: indexPath.section))
    }

    override func tableView(_: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard let favoritesDataSource = favoritesDataSource else { return nil }

        let event = self.event(for: indexPath.section)

        if favoritesDataSource.eventsViewController(self, canFavorite: event) {
            return [.favorite { [weak self] _ in self?.didFavorite(event) }]
        } else {
            return [.unfavorite { [weak self] _ in self?.didUnfavorite(event) }]
        }
    }

    private func didFavorite(_ event: Event) {
        favoritesDelegate?.eventsViewController(self, didFavorite: event)
    }

    private func didUnfavorite(_ event: Event) {
        favoritesDelegate?.eventsViewController(self, didUnfavorite: event)
    }

    private func event(for section: Int) -> Event {
        events[section]
    }

    private func shouldShowLiveIndicator(for event: Event) -> Bool {
        liveDataSource?.eventsViewController(self, shouldShowLiveIndicatorFor: event) ?? false
    }
}

private extension UITableViewCell {
    func configure(with event: Event) {
        textLabel?.text = event.title
        textLabel?.numberOfLines = 0
        textLabel?.font = .fos_preferredFont(forTextStyle: .body)
        accessoryType = .disclosureIndicator
    }

    var showsLiveIndicator: Bool {
        get { imageView?.image == .liveIndicator }
        set { imageView?.image = newValue ? .liveIndicator : nil }
    }
}

private extension UIImage {
    static let liveIndicator: UIImage = {
        let size = CGSize(width: 12, height: 12)
        let rect = CGRect(origin: .zero, size: size)
        let render = UIGraphicsImageRenderer(bounds: rect)
        return render.image { context in
            context.cgContext.setFillColor(UIColor.systemRed.cgColor)
            UIBezierPath(ovalIn: rect).fill()
        }
    }()
}

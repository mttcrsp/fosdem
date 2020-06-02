import UIKit

protocol EventsViewControllerDataSource: AnyObject {
    func events(in eventsViewController: EventsViewController) -> [Event]
    func eventsViewController(_ eventsViewController: EventsViewController, captionFor event: Event) -> String?
}

protocol EventsViewControllerPreviewDelegate: AnyObject {
    func eventsViewController(_ eventsViewController: EventsViewController, previewFor event: Event) -> UIViewController?
    func eventsViewController(_ eventsViewController: EventsViewController, commit previewViewController: UIViewController)
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
    weak var previewDelegate: EventsViewControllerPreviewDelegate?

    var emptyBackgroundTitle: String? {
        get { emptyBackgroundView.title }
        set { emptyBackgroundView.title = newValue }
    }

    var emptyBackgroundMessage: String? {
        get { emptyBackgroundView.message }
        set { emptyBackgroundView.message = newValue }
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
        guard viewIfLoaded?.window != nil else { return }

        var indexPaths: [IndexPath] = []

        for indexPath in tableView.indexPathsForVisibleRows ?? [] {
            if let cell = tableView.cellForRow(at: indexPath) {
                let event = self.event(forSection: indexPath.section)
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
        tableView.estimatedRowHeight = 44
        tableView.estimatedSectionHeaderHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionHeaderHeight = UITableView.automaticDimension
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
        view.text = dataSource?.eventsViewController(self, captionFor: event(forSection: section))
        return view
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let event = self.event(forSection: indexPath.section)
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
        cell.showsLiveIndicator = shouldShowLiveIndicator(for: event)
        cell.configure(with: event)
        return cell
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.eventsViewController(self, didSelect: event(forSection: indexPath.section))
    }

    override func tableView(_: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        [UITableViewRowAction](actions: actions(at: indexPath))
    }

    @available(iOS 11.0, *)
    override func tableView(_: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        UISwipeActionsConfiguration(actions: actions(at: indexPath))
    }

    @available(iOS 13.0, *)
    override func tableView(_: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point _: CGPoint) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(actions: actions(at: indexPath)) { [weak self] in
            guard let self = self else { return nil }
            return self.previewDelegate?.eventsViewController(self, previewFor: self.event(forSection: indexPath.section))
        }
    }

    @available(iOS 13.0, *)
    override func tableView(_: UITableView, willPerformPreviewActionForMenuWith _: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.preferredCommitStyle = .pop
        animator.addCompletion { [weak self, weak animator] in
            guard let self = self, let animator = animator, let previewViewController = animator.previewViewController else { return }
            self.previewDelegate?.eventsViewController(self, commit: previewViewController)
        }
    }

    private func actions(at indexPath: IndexPath) -> [Action] {
        guard let favoritesDataSource = favoritesDataSource else {
            return []
        }

        let event = self.event(forSection: indexPath.section)

        if favoritesDataSource.eventsViewController(self, canFavorite: event) {
            let title = NSLocalizedString("event.add", comment: "")
            let image = UIImage.fos_systemImage(withName: "calendar.badge.plus")
            return [Action(title: title, image: image) { [weak self] in
                self?.didFavorite(event)
            }]
        } else {
            let title = NSLocalizedString("event.remove", comment: "")
            let image = UIImage.fos_systemImage(withName: "calendar.badge.minus")
            return [Action(title: title, image: image, style: .destructive) { [weak self] in
                self?.didUnfavorite(event)
            }]
        }
    }

    private func didFavorite(_ event: Event) {
        favoritesDelegate?.eventsViewController(self, didFavorite: event)
    }

    private func didUnfavorite(_ event: Event) {
        favoritesDelegate?.eventsViewController(self, didUnfavorite: event)
    }

    private func event(forSection section: Int) -> Event {
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

import UIKit

protocol EventsViewControllerDataSource: AnyObject {
    func events(in eventsViewController: EventsViewController) -> [Event]
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

    var emptyBackgroundText: String? {
        get { emptyBackgroundView.text }
        set { emptyBackgroundView.text = newValue }
    }

    private lazy var emptyBackgroundView = TableBackgroundView()

    private var events: [Event] {
        dataSource?.events(in: self) ?? []
    }

    func reloadData() {
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
    }

    override func numberOfSections(in _: UITableView) -> Int {
        let count = events.count
        tableView.backgroundView = count == 0 ? emptyBackgroundView : nil
        return count
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
        cell.configure(with: event(for: indexPath.section))
        return cell
    }

    override func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        event(for: section).formattedStartAndRoom
    }

    override func tableView(_: UITableView, willDisplayHeaderView view: UIView, forSection _: Int) {
        guard let view = view as? UITableViewHeaderFooterView else { return }
        view.textLabel?.font = .fos_preferredFont(forTextStyle: .subheadline)
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
}

private extension Event {
    var formattedStartAndRoom: String {
        guard let formattedStart = formattedStart else { return room }
        return "\(formattedStart) - \(room)"
    }
}

private extension UITableViewCell {
    func configure(with event: Event) {
        textLabel?.text = event.title
        textLabel?.numberOfLines = 0
        accessoryType = .disclosureIndicator
    }
}

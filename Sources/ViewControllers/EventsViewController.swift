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
        if isViewLoaded {
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = .none
        tableView.register(EventTableViewCell.self, forCellReuseIdentifier: EventTableViewCell.reuseIdentifier)
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        let count = events.count
        tableView.backgroundView = count == 0 ? emptyBackgroundView : nil
        return count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: EventTableViewCell.reuseIdentifier, for: indexPath) as! EventTableViewCell
        cell.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        cell.configure(with: event(at: indexPath))
        return cell
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.eventsViewController(self, didSelect: event(at: indexPath))
    }

    override func tableView(_: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard let favoritesDataSource = favoritesDataSource else { return nil }

        let event = self.event(at: indexPath)

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

    private func event(at indexPath: IndexPath) -> Event {
        events[indexPath.row]
    }
}

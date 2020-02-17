import UIKit

protocol EventsViewControllerDataSource: AnyObject {
    func events(in eventsViewController: EventsViewController) -> [Event]
}

protocol EventsViewControllerDelegate: AnyObject {
    func eventsViewController(_ eventsViewController: EventsViewController, didSelect event: Event)
}

final class EventsViewController: UITableViewController {
    weak var dataSource: EventsViewControllerDataSource?
    weak var delegate: EventsViewControllerDelegate?

    private var events: [Event] {
        dataSource?.events(in: self) ?? []
    }

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

    func reloadData() {
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
    }

    override func numberOfSections(in _: UITableView) -> Int {
        events.count
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
        event(for: section).formattedStart
    }

    override func tableView(_: UITableView, willDisplayHeaderView view: UIView, forSection _: Int) {
        guard let view = view as? UITableViewHeaderFooterView else { return }
        view.textLabel?.font = .preferredFont(forTextStyle: .subheadline)
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.eventsViewController(self, didSelect: event(for: indexPath.section))
    }

    private func event(for section: Int) -> Event {
        events[section]
    }
}

private extension UITableViewCell {
    func configure(with event: Event) {
        textLabel?.text = event.title
        textLabel?.numberOfLines = 0
        accessoryType = .disclosureIndicator
    }
}

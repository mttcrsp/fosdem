import UIKit

protocol PlanViewControllerDataSource: AnyObject {
    func events(in planViewController: PlanViewController) -> [Event]
}

protocol PlanViewControllerDelegate: AnyObject {
    func planViewController(_ planViewController: PlanViewController, didSelect event: Event)
    func planViewController(_ planViewController: PlanViewController, didUnfavorite event: Event)
}

final class PlanViewController: UITableViewController {
    weak var dataSource: PlanViewControllerDataSource?
    weak var delegate: PlanViewControllerDelegate?

    private var events: [Event] {
        dataSource?.events(in: self) ?? []
    }

    init() {
        if #available(iOS 13.0, *) {
            super.init(style: .insetGrouped)
        } else {
            super.init(style: .plain)
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        event(for: section).formattedStartAndRoom
    }

    override func tableView(_: UITableView, willDisplayHeaderView view: UIView, forSection _: Int) {
        guard let view = view as? UITableViewHeaderFooterView else { return }
        view.textLabel?.font = .preferredFont(forTextStyle: .subheadline)
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.planViewController(self, didSelect: event(for: indexPath.section))
    }

    override func tableView(_: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        [.unfavorite { [weak self] indexPath in self?.unfavoriteTapped(at: indexPath) }]
    }

    private func unfavoriteTapped(at indexPath: IndexPath) {
        delegate?.planViewController(self, didUnfavorite: event(for: indexPath.section))
    }

    func reloadData() {
        tableView.reloadData()
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

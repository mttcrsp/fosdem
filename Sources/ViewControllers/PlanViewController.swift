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

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        events.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
        cell.configure(with: event(at: indexPath))
        return cell
    }

    private func event(at indexPath: IndexPath) -> Event {
        events[indexPath.row]
    }
}

private extension UITableViewCell {
    func configure(with event: Event) {
        textLabel?.text = event.title
        textLabel?.numberOfLines = 0
        accessoryType = .disclosureIndicator
    }
}

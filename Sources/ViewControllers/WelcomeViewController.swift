import UIKit

protocol WelcomeViewControllerDelegate: AnyObject {
    func welcomeViewControllerDidTapPlan(_ welcomeViewController: WelcomeViewController)
}

final class WelcomeViewController: UITableViewController {
    fileprivate enum Item: CaseIterable {
        case message
        case plan
    }

    weak var delegate: WelcomeViewControllerDelegate?

    private let items = Item.allCases

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
        items.count
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
        cell.configure(with: item(at: indexPath))
        return cell
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        if case .plan = item(at: indexPath) {
            delegate?.welcomeViewControllerDidTapPlan(self)
        }
    }

    private func item(at indexPath: IndexPath) -> Item {
        items[indexPath.section]
    }
}

private extension UITableViewCell {
    func configure(with item: WelcomeViewController.Item) {
        textLabel?.text = item.title
        textLabel?.numberOfLines = 0
    }
}

private extension WelcomeViewController.Item {
    var title: String {
        switch self {
        case .message: return NSLocalizedString("welcome.message", comment: "")
        case .plan: return NSLocalizedString("welcome.plan", comment: "")
        }
    }
}

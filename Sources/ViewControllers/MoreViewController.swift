import UIKit

protocol MoreViewControllerDelegate: AnyObject {
    func moreViewController(_ moreViewController: MoreViewController, didSelect item: MoreItem)
}

final class MoreViewController: UITableViewController {
    weak var delegate: MoreViewControllerDelegate?

    private let items = MoreItem.allCases

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
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
        cell.configure(with: item(at: indexPath))
        return cell
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.moreViewController(self, didSelect: item(at: indexPath))
    }

    private func item(at indexPath: IndexPath) -> MoreItem {
        items[indexPath.row]
    }
}

private extension UITableViewCell {
    func configure(with item: MoreItem) {
        textLabel?.text = item.title
        textLabel?.numberOfLines = 0
        accessoryType = .disclosureIndicator
    }
}

private extension MoreItem {
    var title: String {
        switch self {
        case .years: return NSLocalizedString("years.title", comment: "")
        case .history: return NSLocalizedString("history.title", comment: "")
        case .devrooms: return NSLocalizedString("devrooms.title", comment: "")
        case .speakers: return NSLocalizedString("speakers.title", comment: "")
        case .transportation: return NSLocalizedString("transportation.title", comment: "")
        case .acknowledgements: return NSLocalizedString("acknowledgements.title", comment: "")
        }
    }
}

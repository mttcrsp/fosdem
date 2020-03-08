import UIKit

protocol MoreViewControllerDelegate: AnyObject {
    func moreViewController(_ moreViewController: MoreViewController, didSelect item: MoreItem)
}

final class MoreViewController: UITableViewController {
    weak var delegate: MoreViewControllerDelegate?

    private let sections = MoreSection.allCases

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
    }

    override func numberOfSections(in _: UITableView) -> Int {
        sections.count
    }

    override func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
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
        sections[indexPath.section].items[indexPath.row]
    }
}

extension MoreViewController {
    func addSearchViewController(_ searchController: UISearchController) {
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }
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
        case .transportation: return NSLocalizedString("transportation.title", comment: "")
        case .acknowledgements: return NSLocalizedString("acknowledgements.title", comment: "")
        }
    }
}

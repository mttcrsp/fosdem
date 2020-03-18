import UIKit

protocol TransportationViewControllerDelegate: AnyObject {
    func transportationViewController(_ transportationViewController: TransportationViewController, didSelect item: TransportationViewController.Item)
}

final class TransportationViewController: UITableViewController {
    enum Item {
        case appleMaps
        case googleMaps
    }

    enum Section: CaseIterable {
        case directions
    }

    weak var delegate: TransportationViewControllerDelegate?

    private let sections = Section.allCases

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
        delegate?.transportationViewController(self, didSelect: item(at: indexPath))
    }

    private func item(at indexPath: IndexPath) -> Item {
        sections[indexPath.section].items[indexPath.row]
    }
}

private extension UITableViewCell {
    func configure(with item: TransportationViewController.Item) {
        textLabel?.text = item.title
    }
}

private extension TransportationViewController.Section {
    var title: String {
        switch self {
        case .directions: return NSLocalizedString("transportation.section.directions", comment: "")
        }
    }

    var items: [TransportationViewController.Item] {
        switch self {
        case .directions: return [.appleMaps, .googleMaps]
        }
    }
}

private extension TransportationViewController.Item {
    var title: String {
        switch self {
        case .appleMaps: return NSLocalizedString("transportation.item.apple", comment: "")
        case .googleMaps: return NSLocalizedString("transportation.item.google", comment: "")
        }
    }
}

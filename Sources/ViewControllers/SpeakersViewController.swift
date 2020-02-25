import UIKit

protocol SpeakersViewControllerDelegate: AnyObject {
    func speakersViewController(_ speakersViewController: SpeakersViewController, didEnter query: String)
    func speakersViewController(_ speakersViewController: SpeakersViewController, didSelect person: Person)
}

protocol SpeakersViewControllerDataSource: AnyObject {
    var speakers: [Person] { get }
}

final class SpeakersViewController: UITableViewController {
    weak var dataSource: SpeakersViewControllerDataSource?
    weak var delegate: SpeakersViewControllerDelegate?

    private lazy var searchController = UISearchController(searchResultsController: nil)

    private var speakers: [Person] {
        dataSource?.speakers ?? []
    }

    func reloadData() {
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = NSLocalizedString("speakers.search", comment: "")
        searchController.searchResultsUpdater = self

        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        speakers.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
        cell.configure(with: speakers(at: indexPath))
        return cell
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.speakersViewController(self, didSelect: speakers(at: indexPath))
    }

    private func speakers(at indexPath: IndexPath) -> Person {
        speakers[indexPath.row]
    }
}

extension SpeakersViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        delegate?.speakersViewController(self, didEnter: searchController.searchBar.text ?? "")
    }
}

private extension UITableViewCell {
    func configure(with person: Person) {
        textLabel?.numberOfLines = 0
        textLabel?.text = person.name
        accessoryType = .disclosureIndicator
    }
}

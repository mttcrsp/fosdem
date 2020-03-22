import UIKit

extension UITableViewController {
    func deselectSelectedRow(animated: Bool) {
        if let indexPathForSelectedRow = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPathForSelectedRow, animated: animated)
        }
    }
}

extension UITableViewController {
    func addSearchViewController(_ searchController: UISearchController) {
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            addEmbeddedSearchViewController(searchController)
        }
    }

    func addEmbeddedSearchViewController(_ searchController: UISearchController) {
        tableView.tableHeaderView = searchController.searchBar
    }
}

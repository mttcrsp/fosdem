import UIKit

public extension UITableViewController {
  func deselectSelectedRow(animated: Bool) {
    if let indexPathForSelectedRow = tableView.indexPathForSelectedRow {
      tableView.deselectRow(at: indexPathForSelectedRow, animated: animated)
    }
  }
}

public extension UITableViewController {
  func addSearchViewController(_ searchController: UISearchController) {
    navigationItem.searchController = searchController
    navigationItem.hidesSearchBarWhenScrolling = false
  }
}

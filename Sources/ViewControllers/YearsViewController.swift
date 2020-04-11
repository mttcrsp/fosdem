import UIKit

protocol YearsViewControllerDataSource: AnyObject {
    func numberOfYears(in yearsViewController: YearsViewController) -> Int
    func yearsViewController(_ yearsViewController: YearsViewController, yearAt index: Int) -> String
}

protocol YearsViewControllerDelegate: AnyObject {
    func yearsViewController(_ yearsViewController: YearsViewController, didSelect year: String)
}

final class YearsViewController: UITableViewController {
    weak var dataSource: YearsViewControllerDataSource?
    weak var delegate: YearsViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        dataSource?.numberOfYears(in: self) ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
        cell.textLabel?.text = year(at: indexPath)
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let year = year(at: indexPath) {
            delegate?.yearsViewController(self, didSelect: year)
        }
    }

    private func year(at indexPath: IndexPath) -> String? {
        dataSource?.yearsViewController(self, yearAt: indexPath.row)
    }
}

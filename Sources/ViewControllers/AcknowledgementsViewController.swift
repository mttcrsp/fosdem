import UIKit

protocol AcknowledgementsViewControllerDataSource: AnyObject {
    var acknowledgements: [Acknowledgement] { get }
}

protocol AcknowledgementsViewControllerDelegate: AnyObject {
    func acknowledgementsViewController(_ acknowledgementsViewController: AcknowledgementsViewController, didSelect acknowledgement: Acknowledgement)
}

final class AcknowledgementsViewController: UITableViewController {
    weak var dataSource: AcknowledgementsViewControllerDataSource?
    weak var delegate: AcknowledgementsViewControllerDelegate?

    private var acknowledgements: [Acknowledgement] {
        dataSource?.acknowledgements ?? []
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        acknowledgements.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
        cell.textLabel?.text = acknowledgement(at: indexPath)
        return cell
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.acknowledgementsViewController(self, didSelect: acknowledgement(at: indexPath))
    }

    private func acknowledgement(at indexPath: IndexPath) -> Acknowledgement {
        acknowledgements[indexPath.row]
    }
}

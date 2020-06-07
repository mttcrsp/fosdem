import UIKit

private typealias Year = String

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
    tableView.estimatedRowHeight = 44
    tableView.tableFooterView = UIView()
    tableView.rowHeight = UITableView.automaticDimension
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
  }

  override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    dataSource?.numberOfYears(in: self) ?? 0
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
    if let year = year(at: indexPath) {
      cell.configure(with: year)
    }
    return cell
  }

  override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    if let year = year(at: indexPath) {
      delegate?.yearsViewController(self, didSelect: year)
    }
  }

  private func year(at indexPath: IndexPath) -> Year? {
    dataSource?.yearsViewController(self, yearAt: indexPath.row)
  }
}

private extension UITableViewCell {
  func configure(with year: Year) {
    accessoryType = .disclosureIndicator

    let format = NSLocalizedString("years.year", comment: "")
    let string = String(format: format, year)
    textLabel?.text = string
    textLabel?.font = .fos_preferredFont(forTextStyle: .body)

    if #available(iOS 13.0, *), let number = Int(year) {
      imageView?.image = UIImage(systemName: "\(number % 2000).circle.fill")
    }
  }
}

import UIKit

typealias Year = Int

enum YearDownloadState: CaseIterable {
  case available, inProgress, completed
}

/// @mockable
protocol YearsViewControllerDataSource: AnyObject {
  func numberOfYears(in yearsViewController: YearsViewController) -> Int
  func yearsViewController(_ yearsViewController: YearsViewController, yearAt index: Int) -> Year
  func yearsViewController(_ yearsViewController: YearsViewController, downloadStateAt index: Int) -> YearDownloadState
}

/// @mockable
protocol YearsViewControllerDelegate: AnyObject {
  func yearsViewController(_ yearsViewController: YearsViewController, didSelectYearAt index: Int)
}

class YearsViewController: UITableViewController {
  weak var dataSource: YearsViewControllerDataSource?
  weak var delegate: YearsViewControllerDelegate?

  func reloadRow(at index: Int) {
    let indexPaths = [IndexPath(row: index, section: 0)]
    tableView.reloadRows(at: indexPaths, with: .none)
  }

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
    if let state = downloadState(at: indexPath) {
      cell.setDownloadState(state)
    }
    return cell
  }

  override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    delegate?.yearsViewController(self, didSelectYearAt: indexPath.row)
  }

  private func year(at indexPath: IndexPath) -> Year? {
    dataSource?.yearsViewController(self, yearAt: indexPath.row)
  }

  private func downloadState(at indexPath: IndexPath) -> YearDownloadState? {
    dataSource?.yearsViewController(self, downloadStateAt: indexPath.row)
  }
}

private extension UITableViewCell {
  func configure(with year: Year) {
    accessibilityIdentifier = year.description
    textLabel?.font = .fos_preferredFont(forTextStyle: .body)
    textLabel?.text = L10n.Years.year(year)

    if #available(iOS 13.0, *) {
      imageView?.image = UIImage(systemName: "\(year % 2000).circle.fill")
    }
  }

  func setDownloadState(_ state: YearDownloadState) {
    switch state {
    case .inProgress:
      let indicatorView = UIActivityIndicatorView(style: preferredIndicatorStyle)
      indicatorView.startAnimating()
      accessoryView = indicatorView
      accessoryType = .none
    case .available, .completed:
      accessoryView = nil
      accessoryType = .disclosureIndicator
    }
  }

  private var preferredIndicatorStyle: UIActivityIndicatorView.Style {
    if #available(iOS 12.0, *), traitCollection.userInterfaceStyle == .dark {
      return .white
    } else {
      return .gray
    }
  }
}

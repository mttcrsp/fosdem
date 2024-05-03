import UIKit

protocol AcknowledgementsViewControllerDelegate: AnyObject {
  func acknowledgementsViewController(_ acknowledgementsViewController: AcknowledgementsViewController, didSelect acknowledgement: Acknowledgement)
}

final class AcknowledgementsViewController: UITableViewController {
  weak var delegate: AcknowledgementsViewControllerDelegate?
  private let acknowledgements: [Acknowledgement]

  init(acknowledgements: [Acknowledgement], style: UITableView.Style) {
    self.acknowledgements = acknowledgements
    super.init(style: style)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.estimatedRowHeight = 44
    tableView.rowHeight = UITableView.automaticDimension
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
  }

  override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    acknowledgements.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let acknowledgement = acknowledgement(at: indexPath)
    let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
    cell.accessoryType = .disclosureIndicator
    cell.textLabel?.text = acknowledgement.name
    cell.textLabel?.font = .fos_preferredFont(forTextStyle: .body)
    return cell
  }

  override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    delegate?.acknowledgementsViewController(self, didSelect: acknowledgement(at: indexPath))
  }

  private func acknowledgement(at indexPath: IndexPath) -> Acknowledgement {
    acknowledgements[indexPath.row]
  }
}

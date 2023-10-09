import UIKit

final class AcknowledgementsViewController: UITableViewController {
  var onAcknowledgementTap: ((Acknowledgement) -> Void)?
  var acknowledgements: [Acknowledgement] = []

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
    let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
    cell.configure(with: acknowledgement(at: indexPath))
    return cell
  }

  override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    onAcknowledgementTap?(acknowledgement(at: indexPath))
  }

  private func acknowledgement(at indexPath: IndexPath) -> Acknowledgement {
    acknowledgements[indexPath.row]
  }
}

private extension UITableViewCell {
  func configure(with acknowledgement: Acknowledgement) {
    accessoryType = .disclosureIndicator
    textLabel?.text = acknowledgement.name
    textLabel?.font = .fos_preferredFont(forTextStyle: .body)
  }
}

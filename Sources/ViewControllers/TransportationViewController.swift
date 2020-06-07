import UIKit

protocol TransportationViewControllerDelegate: AnyObject {
  func transportationViewController(_ transportationViewController: TransportationViewController, didSelect item: TransportationViewController.Item)
}

final class TransportationViewController: UITableViewController {
  enum Item {
    case appleMaps, googleMaps
    case bus, shuttle, train, car, plane, taxi
  }

  enum Section: CaseIterable {
    case directions, by
  }

  weak var delegate: TransportationViewControllerDelegate?

  private let sections = Section.allCases

  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.estimatedRowHeight = 44
    tableView.rowHeight = UITableView.automaticDimension
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
    textLabel?.font = .fos_preferredFont(forTextStyle: .body)
    accessoryType = item.accessoryType
  }
}

private extension TransportationViewController.Section {
  var title: String {
    switch self {
    case .directions:
      return NSLocalizedString("transportation.section.directions", comment: "")
    case .by:
      return NSLocalizedString("transportation.section.by", comment: "")
    }
  }

  var items: [TransportationViewController.Item] {
    switch self {
    case .directions: return [.appleMaps, .googleMaps]
    case .by: return [.bus, .shuttle, .train, .car, .plane, .taxi]
    }
  }
}

extension TransportationViewController.Item {
  var title: String {
    switch self {
    case .googleMaps:
      return NSLocalizedString("transportation.item.google", comment: "")
    case .appleMaps:
      return NSLocalizedString("transportation.item.apple", comment: "")
    case .shuttle:
      return NSLocalizedString("transportation.item.shuttle", comment: "")
    case .train:
      return NSLocalizedString("transportation.item.train", comment: "")
    case .plane:
      return NSLocalizedString("transportation.item.plane", comment: "")
    case .taxi:
      return NSLocalizedString("transportation.item.taxi", comment: "")
    case .car:
      return NSLocalizedString("transportation.item.car", comment: "")
    case .bus:
      return NSLocalizedString("transportation.item.bus", comment: "")
    }
  }
}

private extension TransportationViewController.Item {
  var accessoryType: UITableViewCell.AccessoryType {
    switch self {
    case .bus, .shuttle, .train, .car, .plane, .taxi:
      return .disclosureIndicator
    case .appleMaps, .googleMaps:
      return .none
    }
  }
}

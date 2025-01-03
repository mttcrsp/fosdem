import UIKit

enum TransportationItem: String {
  case appleMaps, googleMaps
  case bus, train, car, plane, taxi
}

enum TransportationSection: CaseIterable {
  case directions, by
}

/// @mockable
protocol TransportationViewControllerDelegate: AnyObject {
  func transportationViewController(_ transportationViewController: TransportationViewController, didSelect item: TransportationItem)
}

final class TransportationViewController: UITableViewController {
  private typealias Item = TransportationItem
  private typealias Section = TransportationSection

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
  func configure(with item: TransportationItem) {
    textLabel?.text = item.title
    textLabel?.font = .fos_preferredFont(forTextStyle: .body)
    accessibilityIdentifier = item.accessibilityIdentifier
    accessoryType = item.accessoryType
  }
}

private extension TransportationSection {
  var title: String {
    switch self {
    case .directions:
      L10n.Transportation.Section.directions
    case .by:
      L10n.Transportation.Section.by
    }
  }

  var items: [TransportationItem] {
    switch self {
    case .directions: [.appleMaps, .googleMaps]
    case .by: [.bus, .train, .car, .plane, .taxi]
    }
  }
}

extension TransportationItem {
  var title: String {
    switch self {
    case .googleMaps:
      L10n.Transportation.Item.google
    case .appleMaps:
      L10n.Transportation.Item.apple
    case .train:
      L10n.Transportation.Item.train
    case .plane:
      L10n.Transportation.Item.plane
    case .taxi:
      L10n.Transportation.Item.taxi
    case .car:
      L10n.Transportation.Item.car
    case .bus:
      L10n.Transportation.Item.bus
    }
  }

  var info: Info? {
    switch self {
    case .bus:
      .bus
    case .car:
      .car
    case .taxi:
      .taxi
    case .plane:
      .plane
    case .train:
      .train
    case .appleMaps, .googleMaps:
      nil
    }
  }
}

private extension TransportationItem {
  var accessoryType: UITableViewCell.AccessoryType {
    switch self {
    case .bus, .train, .car, .plane, .taxi:
      .disclosureIndicator
    case .appleMaps, .googleMaps:
      .none
    }
  }

  var accessibilityIdentifier: String {
    rawValue
  }
}

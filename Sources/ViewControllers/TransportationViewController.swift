import UIKit

/// @mockable
protocol TransportationViewControllerDelegate: AnyObject {
  func transportationViewController(_ transportationViewController: TransportationViewController, didSelect item: TransportationViewController.Item)
}

final class TransportationViewController: UITableViewController {
  enum Item: String, Codable {
    case appleMaps, googleMaps
    case bus, shuttle, train, car, plane, taxi
  }

  enum Section: CaseIterable {
    case directions, by
  }

  weak var delegate: TransportationViewControllerDelegate?

  private let sections = Section.allCases

  private var selectedItem: Item? {
    tableView.indexPathForSelectedRow.flatMap(item)
  }

  override var userActivity: NSUserActivity? {
    set {}
    get {
      if let item = selectedItem, item.supportsStateRestoration {
        return ReadTransportation(item: item).makeUserActivity()
      } else {
        return nil
      }
    }
  }

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
    accessibilityIdentifier = item.accessibilityIdentifier
    accessoryType = item.accessoryType
  }
}

private extension TransportationViewController.Section {
  var title: String {
    switch self {
    case .directions:
      return L10n.Transportation.Section.directions
    case .by:
      return L10n.Transportation.Section.by
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
      return L10n.Transportation.Item.google
    case .appleMaps:
      return L10n.Transportation.Item.apple
    case .shuttle:
      return L10n.Transportation.Item.shuttle
    case .train:
      return L10n.Transportation.Item.train
    case .plane:
      return L10n.Transportation.Item.plane
    case .taxi:
      return L10n.Transportation.Item.taxi
    case .car:
      return L10n.Transportation.Item.car
    case .bus:
      return L10n.Transportation.Item.bus
    }
  }

  var info: Info? {
    switch self {
    case .bus:
      return .bus
    case .car:
      return .car
    case .taxi:
      return .taxi
    case .plane:
      return .plane
    case .train:
      return .train
    case .shuttle:
      return .shuttle
    case .appleMaps, .googleMaps:
      return nil
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

  var supportsStateRestoration: Bool {
    switch self {
    case .bus, .shuttle, .train, .car, .plane, .taxi:
      return true
    case .appleMaps, .googleMaps:
      return false
    }
  }

  var accessibilityIdentifier: String {
    rawValue
  }
}

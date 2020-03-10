import UIKit

protocol EventViewControllerDelegate: AnyObject {
    func eventViewControllerDidTapVideo(_ eventViewController: EventViewController)
}

final class EventViewController: UITableViewController {
    weak var delegate: EventViewControllerDelegate?

    fileprivate struct Item {
        let type: ItemType
        let value: String
    }

    fileprivate enum ItemType {
        case title, subtitle, abstract, duration, video
    }

    var event: Event? {
        didSet { didChangeEvent() }
    }

    private var items: [Item] = [] {
        didSet { didChangeItems() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
    }

    override func numberOfSections(in _: UITableView) -> Int {
        items.count
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.item(forSection: indexPath.section)
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
        cell.selectionStyle = item.type == .video ? .default : .none
        cell.textLabel?.text = item.value
        cell.textLabel?.numberOfLines = 0
        return cell
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = self.item(forSection: indexPath.section)
        if case .video = item.type {
            delegate?.eventViewControllerDidTapVideo(self)
        }
    }

    override func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        item(forSection: section).type.field
    }

    override func tableView(_: UITableView, willDisplayHeaderView view: UIView, forSection _: Int) {
        if let view = view as? UITableViewHeaderFooterView {
            view.textLabel?.font = .preferredFont(forTextStyle: .subheadline)
        }
    }

    private func didChangeEvent() {
        if let event = event {
            items = event.makeItems()
        } else {
            items = []
        }
    }

    private func didChangeItems() {
        tableView.reloadData()
    }

    private func item(forSection section: Int) -> Item {
        items[section]
    }
}

private extension Event {
    func makeItems() -> [EventViewController.Item] {
        var items: [EventViewController.Item] = []
        items.append(.init(type: .title, value: title))

        if let value = subtitle {
            items.append(.init(type: .subtitle, value: value))
        }

        if let value = formattedAbstract {
            items.append(.init(type: .abstract, value: value))
        }

        if let value = formattedDuration {
            items.append(.init(type: .duration, value: value))
        }

        if let _ = video {
            let value = NSLocalizedString("event.video", comment: "")
            items.append(.init(type: .video, value: value))
        }

        return items
    }
}

private extension EventViewController.ItemType {
    var field: String? {
        switch self {
        case .title: return NSLocalizedString("event.title", comment: "")
        case .subtitle: return NSLocalizedString("event.subtitle", comment: "")
        case .abstract: return NSLocalizedString("event.abstract", comment: "")
        case .duration: return NSLocalizedString("event.duration", comment: "")
        case .video: return nil
        }
    }
}

private extension Event {
    var formattedAbstract: String? {
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .characterEncoding: NSNumber(value: String.Encoding.utf8.rawValue),
            .documentType: NSAttributedString.DocumentType.html,
        ]

        guard let abstract = abstract,
            let data = abstract.data(using: .utf8),
            let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            return nil
        }

        return attributedString.string.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var formattedDuration: String? {
        DateComponentsFormatter.default.string(from: duration)
    }
}

private extension DateComponentsFormatter {
    static let `default`: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute]
        return formatter
    }()
}

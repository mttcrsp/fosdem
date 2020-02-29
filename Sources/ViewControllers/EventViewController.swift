import UIKit

protocol EventViewControllerDelegate: AnyObject {
    func eventViewControllerDidTapVideo(_ eventViewController: EventViewController)
}

final class EventViewController: UITableViewController {
    weak var delegate: EventViewControllerDelegate?

    fileprivate struct Item {
        let field: String?
        let value: String
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
        let item = items[indexPath.section]
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
        cell.textLabel?.text = item.value
        cell.textLabel?.numberOfLines = 0
        cell.selectionStyle = item.field == nil ? .default : .none
        return cell
    }

    override func tableView(_: UITableView, didSelectRowAt _: IndexPath) {
        delegate?.eventViewControllerDidTapVideo(self)
    }

    override func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        items[section].field
    }

    override func tableView(_: UITableView, willDisplayHeaderView view: UIView, forSection _: Int) {
        guard let view = view as? UITableViewHeaderFooterView else { return }
        view.textLabel?.font = .preferredFont(forTextStyle: .subheadline)
    }

    private func didChangeEvent() {
        if let event = event {
            items = makeItems(for: event)
        } else {
            items = []
        }
    }

    private func didChangeItems() {
        tableView.reloadData()
    }

    private func makeItems(for event: Event) -> [Item] {
        var items: [Item] = []

        let titleValue = event.title
        let titleField = NSLocalizedString("event.title", comment: "")
        items.append(.init(field: titleField, value: titleValue))

        if let value = event.subtitle {
            let field = NSLocalizedString("event.subtitle", comment: "")
            items.append(.init(field: field, value: value))
        }

        if let value = event.formattedAbstract {
            let field = NSLocalizedString("event.abstract", comment: "")
            items.append(.init(field: field, value: value))
        }

        if let value = event.formattedDuration {
            let field = NSLocalizedString("event.duration", comment: "")
            items.append(.init(field: field, value: value))
        }

        if let _ = event.video {
            let value = NSLocalizedString("event.video", comment: "")
            items.append(.init(field: nil, value: value))
        }

        return items
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

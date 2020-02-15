import UIKit

protocol EventViewControllerDataSource: AnyObject {
    func isEventFavorite(for eventViewController: EventViewController) -> Bool
}

protocol EventViewControllerDelegate: AnyObject {
    func eventViewControllerDidTapVideo(_ eventViewController: EventViewController)
    func eventViewControllerDidTapFavorite(_ eventViewController: EventViewController)
}

final class EventViewController: UITableViewController {
    weak var delegate: EventViewControllerDelegate?
    weak var dataSource: EventViewControllerDataSource? {
        didSet { reloadFavoriteState() }
    }

    fileprivate struct Item {
        let field: String?
        let value: String
    }

    var event: Event? {
        didSet { eventChanged() }
    }

    private var items: [Item] = [] {
        didSet { itemsChanged() }
    }

    private var isEventFavorite: Bool {
        dataSource?.isEventFavorite(for: self) ?? false
    }

    private lazy var favoriteButton: UIBarButtonItem =
        UIBarButtonItem(title: favoriteButtonTitle, style: .plain, target: self, action: #selector(favoriteTapped))

    private var favoriteButtonTitle: String {
        isEventFavorite
            ? NSLocalizedString("Unfavorite", comment: "")
            : NSLocalizedString("Favorite", comment: "")
    }

    init() {
        if #available(iOS 13.0, *) {
            super.init(style: .insetGrouped)
        } else {
            super.init(style: .grouped)
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = favoriteButton
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

    @objc private func favoriteTapped() {
        delegate?.eventViewControllerDidTapFavorite(self)
    }

    func reloadFavoriteState() {
        favoriteButton.title = favoriteButtonTitle
    }

    private func eventChanged() {
        reloadFavoriteState()

        if let event = event {
            items = makeItems(for: event)
        } else {
            items = []
        }
    }

    private func itemsChanged() {
        tableView.reloadData()
    }

    private func makeItems(for event: Event) -> [Item] {
        var items: [Item] = []

        let titleValue = event.title
        let titleField = NSLocalizedString("Title", comment: "")
        items.append(.init(field: titleField, value: titleValue))

        if let value = event.subtitle {
            let field = NSLocalizedString("Subtitle", comment: "")
            items.append(.init(field: field, value: value))
        }

        if let value = event.formattedAbstract {
            let field = NSLocalizedString("Abstract", comment: "")
            items.append(.init(field: field, value: value))
        }

        if let value = event.formattedDuration {
            let field = NSLocalizedString("Duration", comment: "")
            items.append(.init(field: field, value: value))
        }

        if let _ = event.video {
            let value = NSLocalizedString("Watch now", comment: "")
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

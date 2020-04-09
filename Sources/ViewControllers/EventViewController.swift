import UIKit

protocol EventViewControllerDelegate: AnyObject {
    func eventViewControllerDidTapVideo(_ eventViewController: EventViewController)
    func eventViewController(_ eventViewController: EventViewController, didSelect attachment: Attachment)
}

final class EventViewController: UITableViewController {
    weak var delegate: EventViewControllerDelegate?

    var event: Event? {
        didSet { didChangeEvent() }
    }

    fileprivate enum Item {
        case title
        case track
        case video
        case people
        case room
        case date
        case subtitle
        case abstract
        case summary
        case attachments
        case attachment(Attachment)
    }

    private var items: [Item] = [] {
        didSet { didChangeItems() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = .none
        tableView.tableFooterView = .init()
        tableView.register(TableViewCell.self, forCellReuseIdentifier: TableViewCell.reuseIdentifier)
        tableView.register(TrackTableViewCell.self, forCellReuseIdentifier: TrackTableViewCell.reuseIdentifier)
        tableView.register(RoundedButtonTableViewCell.self, forCellReuseIdentifier: RoundedButtonTableViewCell.reuseIdentifier)
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let event = event else { return UITableViewCell() }

        switch items[indexPath.row] {
        case .title:
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCell.reuseIdentifier, for: indexPath)
            cell.textLabel?.font = .fos_preferredFont(forTextStyle: .title1, withSymbolicTraits: .traitBold)
            cell.textLabel?.text = event.title
            return cell
        case .track:
            let cell = tableView.dequeueReusableCell(withIdentifier: TrackTableViewCell.reuseIdentifier, for: indexPath) as! TrackTableViewCell
            cell.track = event.track
            return cell
        case .people:
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCell.reuseIdentifier, for: indexPath)
            cell.textLabel?.font = .fos_preferredFont(forTextStyle: .subheadline)
            cell.textLabel?.text = event.formattedPeople

            if #available(iOS 13.0, *) {
                cell.imageView?.image = UIImage(systemName: "person.fill")
            } else {
                cell.imageView?.image = UIImage(named: "person.fill")
            }

            return cell
        case .room:
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCell.reuseIdentifier, for: indexPath)
            cell.textLabel?.font = .fos_preferredFont(forTextStyle: .subheadline)
            cell.textLabel?.text = event.room

            if #available(iOS 13.0, *) {
                cell.imageView?.image = UIImage(systemName: "mappin.circle.fill")
            } else {
                cell.imageView?.image = UIImage(named: "mappin.circle.fill")
            }

            return cell
        case .date:
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCell.reuseIdentifier, for: indexPath)
            cell.textLabel?.font = .fos_preferredFont(forTextStyle: .subheadline)
            cell.textLabel?.text = event.formattedStart

            if #available(iOS 13.0, *) {
                cell.imageView?.image = UIImage(systemName: "clock.fill")
            } else {
                cell.imageView?.image = UIImage(named: "clock.fill")
            }

            return cell
        case .subtitle:
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCell.reuseIdentifier, for: indexPath)
            cell.textLabel?.font = .fos_preferredFont(forTextStyle: .headline)
            cell.textLabel?.text = event.subtitle
            return cell
        case .video:
            let videoAction = #selector(didTapVideo)
            let videoTitle = NSLocalizedString("event.video", comment: "")
            let cell = tableView.dequeueReusableCell(withIdentifier: RoundedButtonTableViewCell.reuseIdentifier, for: indexPath) as! RoundedButtonTableViewCell
            cell.button.addTarget(self, action: videoAction, for: .touchUpInside)
            cell.button.setTitle(videoTitle, for: .normal)
            return cell
        case .abstract:
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCell.reuseIdentifier, for: indexPath)
            cell.textLabel?.font = .fos_preferredFont(forTextStyle: .body)
            cell.textLabel?.text = event.formattedAbstract
            return cell
        case .summary:
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCell.reuseIdentifier, for: indexPath)
            cell.textLabel?.font = .fos_preferredFont(forTextStyle: .body)
            cell.textLabel?.text = event.formattedSummary
            return cell
        case .attachments:
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCell.reuseIdentifier, for: indexPath)
            cell.textLabel?.text = NSLocalizedString("event.attachments", comment: "")
            cell.textLabel?.font = .fos_preferredFont(forTextStyle: .headline)
            return cell
        case let .attachment(attachment):
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCell.reuseIdentifier, for: indexPath)
            cell.textLabel?.font = .fos_preferredFont(forTextStyle: .body, withSymbolicTraits: [.traitItalic])
            cell.textLabel?.text = attachment.title
            return cell
        }
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        if case let .attachment(attachment) = items[indexPath.row] {
            delegate?.eventViewController(self, didSelect: attachment)
        }
    }

    @objc private func didTapVideo() {
        delegate?.eventViewControllerDidTapVideo(self)
    }

    private func didChangeEvent() {
        if let event = event {
            items = event.makeItems()
        } else {
            items = []
        }
    }

    private func didChangeItems() {
        if isViewLoaded {
            tableView.reloadData()
        }
    }

    private final class TableViewCell: UITableViewCell {
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            selectionStyle = .none
            textLabel?.numberOfLines = 0
        }

        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            imageView?.image = nil
            textLabel?.font = nil
            textLabel?.text = nil
            accessoryView = nil
        }
    }
}

private extension Event {
    var formattedAbstract: String? {
        guard let abstract = abstract, let html = abstract.data(using: .utf8), let attributedString = try? NSAttributedString(html: html) else { return nil }

        var string = attributedString.string
        string = string.trimmingCharacters(in: .whitespacesAndNewlines)
        string = string.replacingOccurrences(of: "\n", with: "\n\n")
        return string
    }

    var formattedSummary: String? {
        summary?.replacingOccurrences(of: "\n", with: "\n\n")
    }

    var formattedDuration: String? {
        DateComponentsFormatter.default.string(from: duration)
    }

    var formattedPeople: String? {
        people.map { person in person.name }.joined(separator: ", ")
    }
}

private extension DateComponentsFormatter {
    static let `default`: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute]
        return formatter
    }()
}

private extension Event {
    func makeItems() -> [EventViewController.Item] {
        var items: [EventViewController.Item] = [.title, .track]

        if video != nil {
            items.append(.video)
        }

        if !people.isEmpty {
            items.append(.people)
        }

        items.append(contentsOf: [.room, .date])

        if subtitle != nil {
            items.append(.subtitle)
        }

        if abstract != nil {
            items.append(.abstract)
        }

        if summary != nil {
            items.append(.summary)
        }

        let attachments = self.attachments.filter { attachment in
            attachment.title != nil
        }

        if !attachments.isEmpty {
            items.append(.attachments)
        }

        for attachment in attachments {
            items.append(.attachment(attachment))
        }

        return items
    }
}

private extension Attachment {
    var title: String? {
        switch (name, type.title) {
        case (nil, nil):
            return nil
        case (let value?, nil), (nil, let value?):
            return value
        case let (name?, type?):
            let lowercaseName = name.lowercased()
            let lowercaseType = type.lowercased()
            if lowercaseName.contains(lowercaseType) {
                return name
            } else {
                return "\(name) (\(type))"
            }
        }
    }
}

private extension AttachmentType {
    var title: String? {
        switch self {
        case .slides: return NSLocalizedString("attachment.slides", comment: "")
        case .audio: return NSLocalizedString("attachment.audio", comment: "")
        case .paper: return NSLocalizedString("attachment.paper", comment: "")
        case .video: return NSLocalizedString("attachment.video", comment: "")
        case .other: return nil
        }
    }
}

// EventViewController.Item.allCases.filter { item in
//    switch item {
//    case .title, .track, .room, .date: return true
//    case .video: return video != nil
//    case .summary: return summary != nil
//    case .subtitle: return subtitle != nil
//    case .abstract: return abstract != nil
//    case .people: return
//    }
// }

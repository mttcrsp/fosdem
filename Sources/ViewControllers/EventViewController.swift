import UIKit

protocol EventViewControllerDelegate: AnyObject {
    func eventViewControllerDidTapVideo(_ eventViewController: EventViewController)
}

final class EventViewController: UITableViewController {
    weak var delegate: EventViewControllerDelegate?

    var event: Event? {
        didSet { didChangeEvent() }
    }

    fileprivate enum Item: CaseIterable {
        case title, track, video, people, room, date, subtitle, abstract, summary
    }

    private var items: [Item] = [] {
        didSet { didChangeItems() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.tableFooterView = .init()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
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
            let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
            cell.textLabel?.font = .fos_preferredFont(forTextStyle: .title1, withSymbolicTraits: .traitBold)
            cell.textLabel?.text = event.title
            cell.textLabel?.numberOfLines = 0
            return cell
        case .track:
            let cell = tableView.dequeueReusableCell(withIdentifier: TrackTableViewCell.reuseIdentifier, for: indexPath) as! TrackTableViewCell
            cell.track = event.track
            return cell
        case .people:
            let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
            cell.textLabel?.font = .fos_preferredFont(forTextStyle: .subheadline)
            cell.textLabel?.text = event.formattedPeople
            cell.textLabel?.numberOfLines = 0

            if #available(iOS 13.0, *) {
                cell.imageView?.image = UIImage(systemName: "person.fill")
            } else {
                cell.imageView?.image = UIImage(named: "person.fill")
            }

            return cell
        case .room:
            let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
            cell.textLabel?.font = .fos_preferredFont(forTextStyle: .subheadline)
            cell.textLabel?.text = event.room
            cell.textLabel?.numberOfLines = 0

            if #available(iOS 13.0, *) {
                cell.imageView?.image = UIImage(systemName: "mappin.circle.fill")
            } else {
                cell.imageView?.image = UIImage(named: "mappin.circle.fill")
            }

            return cell
        case .date:
            let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
            cell.textLabel?.font = .fos_preferredFont(forTextStyle: .subheadline)
            cell.textLabel?.text = event.formattedStart
            cell.textLabel?.numberOfLines = 0

            if #available(iOS 13.0, *) {
                cell.imageView?.image = UIImage(systemName: "clock.fill")
            } else {
                cell.imageView?.image = UIImage(named: "clock.fill")
            }

            return cell
        case .subtitle:
            let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
            cell.textLabel?.font = .fos_preferredFont(forTextStyle: .headline)
            cell.textLabel?.text = event.subtitle
            cell.textLabel?.numberOfLines = 0
            return cell
        case .video:
            let videoAction = #selector(didTapVideo)
            let videoTitle = NSLocalizedString("event.video", comment: "")
            let cell = tableView.dequeueReusableCell(withIdentifier: RoundedButtonTableViewCell.reuseIdentifier, for: indexPath) as! RoundedButtonTableViewCell
            cell.button.addTarget(self, action: videoAction, for: .touchUpInside)
            cell.button.setTitle(videoTitle, for: .normal)
            return cell
        case .abstract:
            let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
            cell.textLabel?.text = event.formattedAbstract
            cell.textLabel?.numberOfLines = 0
            return cell
        case .summary:
            let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
            cell.textLabel?.text = event.formattedSummary
            cell.textLabel?.numberOfLines = 0
            return cell
        }
    }

    @objc private func didTapVideo() {
        delegate?.eventViewControllerDidTapVideo(self)
    }

    private func didChangeEvent() {
        if let event = event {
            items = Item.makeItems(for: event)
        } else {
            items = []
        }
    }

    private func didChangeItems() {
        tableView.reloadData()
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

private extension EventViewController.Item {
    static func makeItems(for event: Event) -> [EventViewController.Item] {
        allCases.filter { item in
            switch item {
            case .title, .track, .room, .date: return true
            case .people: return !event.people.isEmpty
            case .video: return event.video != nil
            case .summary: return event.summary != nil
            case .subtitle: return event.subtitle != nil
            case .abstract: return event.abstract != nil
            }
        }
    }
}

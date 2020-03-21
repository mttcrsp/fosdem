import UIKit

protocol YearControllerDelegate: AnyObject {
    func yearControllerDidError(_ yearController: YearController)
}

final class YearController: UIViewController {
    weak var delegate: YearControllerDelegate?

    private weak var eventsViewController: EventsViewController?

    private var tracks: [Track] = []
    private var events: [Event] = []

    private let year: String
    private let persistenceService: PersistenceService

    init(year: String, persistenceService: PersistenceService) {
        self.year = year
        self.persistenceService = persistenceService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        persistenceService.performRead(AllTracksOrderedByName()) { result in
            DispatchQueue.main.async { [weak self] in
                switch result {
                case let .failure(error): self?.tracksLoadingDidError(with: error)
                case let .success(tracks): self?.tracksLoadingDidFinish(with: tracks)
                }
            }
        }
    }

    private func tracksLoadingDidError(with error: Error) {
        assertionFailure(error.localizedDescription)
        delegate?.yearControllerDidError(self)
    }

    private func tracksLoadingDidFinish(with tracks: [Track]) {
        self.tracks = tracks

        let tracksViewController = makeTracksViewController()
        addChild(tracksViewController)
        view.addSubview(tracksViewController.view)
        tracksViewController.didMove(toParent: self)
    }
}

extension YearController: TracksViewControllerDataSource, TracksViewControllerDelegate {
    func numberOfSections(in _: TracksViewController) -> Int {
        1
    }

    func sectionIndexTitles(for _: TracksViewController) -> [String]? {
        nil
    }

    func tracksViewController(_: TracksViewController, numberOfTracksIn _: Int) -> Int {
        tracks.count
    }

    func tracksViewController(_: TracksViewController, trackAt indexPath: IndexPath) -> Track {
        tracks[indexPath.row]
    }

    func tracksViewController(_ tracksViewController: TracksViewController, didSelect track: Track) {
        let eventsViewController = makeEventsViewController(for: track)
        tracksViewController.show(eventsViewController, sender: nil)

        events = []
        persistenceService.performRead(EventsForTrack(track: track.name)) { result in
            DispatchQueue.main.async { [weak self] in
                switch result {
                case let .failure(error): self?.eventsLoadingDidError(with: error)
                case let .success(events): self?.eventsLoadingDidFinish(with: events)
                }
            }
        }
    }

    private func eventsLoadingDidError(with error: Error) {
        assertionFailure(error.localizedDescription)
        delegate?.yearControllerDidError(self)
    }

    private func eventsLoadingDidFinish(with events: [Event]) {
        self.events = events
        eventsViewController?.reloadData()
    }
}

extension YearController: EventsViewControllerDataSource, EventsViewControllerDelegate {
    func events(in _: EventsViewController) -> [Event] {
        events
    }

    func eventsViewController(_ eventsViewController: EventsViewController, didSelect event: Event) {
        let eventViewController = makeEventViewController(for: event)
        eventsViewController.show(eventViewController, sender: nil)
    }
}

private extension YearController {
    func makeTracksViewController() -> TracksViewController {
        let tracksViewController = TracksViewController()
        tracksViewController.dataSource = self
        tracksViewController.delegate = self
        tracksViewController.title = year
        return tracksViewController
    }

    func makeEventsViewController(for track: Track) -> EventsViewController {
        let eventsViewController = EventsViewController(style: .grouped)
        eventsViewController.title = track.name
        eventsViewController.dataSource = self
        eventsViewController.delegate = self
        self.eventsViewController = eventsViewController
        return eventsViewController
    }

    func makeEventViewController(for event: Event) -> EventController {
        .init(event: event)
    }
}

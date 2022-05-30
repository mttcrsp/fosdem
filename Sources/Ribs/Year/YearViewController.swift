import RIBs
import UIKit

protocol YearPresentableListener: AnyObject {
  func select(_ event: Event)
  func select(_ track: Track)
}

final class YearViewController: TracksViewController {
  weak var listener: YearPresentableListener?

  var year: Year? {
    didSet { title = year?.description }
  }

  var events: [Event] = [] {
    didSet { eventsViewController?.reloadData() }
  }

  var tracks: [Track] = [] {
    didSet { reloadData() }
  }

  private weak var eventsViewController: EventsViewController?
  private var searchController: UISearchController?

  override func viewDidLoad() {
    super.viewDidLoad()

    delegate = self
    dataSource = self
    definesPresentationContext = true
    navigationItem.largeTitleDisplayMode = .never
    view.backgroundColor = .groupTableViewBackground
  }
}

extension YearViewController: YearViewControllable {
  func addSearch(_ searchViewControllable: ViewControllable) {
    if let searchController = searchViewControllable.uiviewController as? UISearchController {
      addSearchViewController(searchController)
    }
  }

  func showEvent(_ eventViewControllable: ViewControllable) {
    let eventViewController = eventViewControllable.uiviewController
    eventsViewController?.show(eventViewController, sender: nil)
  }

  func showSearchResult(_ eventViewControllable: ViewControllable) {
    let resultViewController = eventViewControllable.uiviewController
    show(resultViewController, sender: nil)
  }
}

extension YearViewController: YearPresentable {
  func showError() {
    let errorViewController = UIAlertController.makeErrorController()
    present(errorViewController, animated: true)
  }

  func showEvents(for track: Track) {
    let eventsViewController = EventsViewController(style: .grouped)
    eventsViewController.title = track.name
    eventsViewController.dataSource = self
    eventsViewController.delegate = self
    self.eventsViewController = eventsViewController
  }
}

extension YearViewController: TracksViewControllerDataSource {
  func numberOfSections(in _: TracksViewController) -> Int {
    1
  }

  func tracksViewController(_: TracksViewController, numberOfTracksIn _: Int) -> Int {
    tracks.count
  }

  func tracksViewController(_: TracksViewController, trackAt indexPath: IndexPath) -> Track {
    tracks[indexPath.row]
  }
}

extension YearViewController: TracksViewControllerDelegate {
  func tracksViewController(_: TracksViewController, didSelect track: Track) {
    listener?.select(track)
  }
}

extension YearViewController: EventsViewControllerDataSource {
  func events(in _: EventsViewController) -> [Event] {
    events
  }

  func eventsViewController(_: EventsViewController, captionFor event: Event) -> String? {
    event.formattedPeople
  }
}

extension YearViewController: EventsViewControllerDelegate {
  func eventsViewController(_: EventsViewController, didSelect event: Event) {
    listener?.select(event)
  }
}

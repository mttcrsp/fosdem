import RIBs
import UIKit

protocol YearPresentableListener: AnyObject {
  var year: Year { get }
  var events: [Event] { get }
  var tracks: [Track] { get }
  func select(_ event: Event)
  func select(_ track: Track)
}

final class YearContainerViewController: TracksViewController {
  weak var listener: YearPresentableListener?

  private weak var eventsViewController: EventsViewController?
  private var searchController: UISearchController?

  override func viewDidLoad() {
    super.viewDidLoad()

    delegate = self
    dataSource = self
    definesPresentationContext = true
    view.backgroundColor = .groupTableViewBackground
    navigationItem.largeTitleDisplayMode = .never
    title = listener?.year.description
  }
}

extension YearContainerViewController: YearViewControllable {
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

extension YearContainerViewController: YearPresentable {
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

extension YearContainerViewController: TracksViewControllerDataSource, TracksViewControllerDelegate {
  private var events: [Event] {
    listener?.events ?? []
  }

  private var tracks: [Track] {
    listener?.tracks ?? []
  }

  func numberOfSections(in _: TracksViewController) -> Int {
    1
  }

  func tracksViewController(_: TracksViewController, numberOfTracksIn _: Int) -> Int {
    tracks.count
  }

  func tracksViewController(_: TracksViewController, trackAt indexPath: IndexPath) -> Track {
    tracks[indexPath.row]
  }

  func tracksViewController(_: TracksViewController, didSelect track: Track) {
    listener?.select(track)
  }
}

extension YearContainerViewController: EventsViewControllerDataSource, EventsViewControllerDelegate {
  func events(in _: EventsViewController) -> [Event] {
    listener?.events ?? []
  }

  func eventsViewController(_: EventsViewController, captionFor event: Event) -> String? {
    event.formattedPeople
  }

  func eventsViewController(_: EventsViewController, didSelect event: Event) {
    listener?.select(event)
  }
}

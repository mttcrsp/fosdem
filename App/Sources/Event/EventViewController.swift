import AVKit
import Combine
import SafariServices
import UIKit

final class EventViewController: UITableViewController {
  typealias Dependencies = HasNavigationService

  private lazy var eventCell: EventTableViewCell = {
    let cell = EventTableViewCell(isAdaptive: isAdaptive)
    cell.configure(with: viewModel.event)
    cell.delegate = self
    cell.dataSource = self
    return cell
  }()

  private var cancellables: [AnyCancellable] = []
  private weak var playerViewController: AVPlayerViewController?
  private let dependencies: Dependencies
  private let viewModel: EventViewModel

  init(dependencies: Dependencies, viewModel: EventViewModel) {
    self.dependencies = dependencies
    self.viewModel = viewModel
    super.init(style: UIDevice.current.userInterfaceIdiom == .pad ? .insetGrouped : .plain)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    viewModel.didUnload()
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.separatorStyle = .none
    tableView.accessibilityIdentifier = "event"
    if isAdaptive {
      tableView.contentInset.top = 8
      tableView.contentInset.bottom = 20
    }

    navigationItem.backButtonTitle = viewModel.event.title
    navigationItem.largeTitleDisplayMode = .never

    viewModel.didLoadVideoURL
      .receive(on: DispatchQueue.main)
      .sink { [weak self] url in
        guard let self else { return }

        let playerViewController = AVPlayerViewController()
        playerViewController.exitsFullScreenWhenPlaybackEnds = true
        playerViewController.player = AVPlayer(url: url)
        playerViewController.player?.play()
        playerViewController.delegate = self
        self.playerViewController = playerViewController
        present(playerViewController, animated: true)
      }
      .store(in: &cancellables)

    viewModel.didUpdatePlaybackPosition
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.eventCell.reloadPlaybackPosition()
      }
      .store(in: &cancellables)

    viewModel.didLoadTrack
      .receive(on: DispatchQueue.main)
      .sink { [weak self] result in
        guard let self else { return }

        switch result {
        case .failure, .success(nil):
          let errorViewController = UIAlertController.makeErrorController()
          show(errorViewController, sender: nil)
        case let .success(track?):
          let style = traitCollection.userInterfaceIdiom == .pad ? UITableView.Style.insetGrouped : .grouped
          let trackViewController = dependencies.navigationService.makeTrackViewController(for: track, style: style)
          trackViewController.title = track.formattedName
          trackViewController.didError = { [weak self] _, _ in
            guard let self else { return }
            let errorViewController = UIAlertController.makeErrorController()
            navigationController?.popViewController(animated: true)
            show(errorViewController, sender: nil)
          }
          show(trackViewController, sender: nil)
        }
      }
      .store(in: &cancellables)

    if viewModel.options.contains(.enableFavoriting) {
      let favoriteAction = #selector(didToggleFavorite)
      let favoriteButton = UIBarButtonItem(title: nil, style: .plain, target: self, action: favoriteAction)
      navigationItem.rightBarButtonItem = favoriteButton

      viewModel.$isEventFavorite
        .receive(on: DispatchQueue.main)
        .sink { isFavorite in
          favoriteButton.accessibilityIdentifier = isFavorite ? "unfavorite" : "favorite"
          favoriteButton.title = isFavorite ? L10n.Event.remove : L10n.Event.add
        }
        .store(in: &cancellables)
    }

    viewModel.didLoad()
  }

  override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    1
  }

  override func tableView(_: UITableView, cellForRowAt _: IndexPath) -> UITableViewCell {
    eventCell
  }
}

extension EventViewController: EventViewDelegate, EventViewDataSource {
  func eventViewDidTapLivestream(_: EventView) {
    viewModel.didSelectLivestream()
  }

  func eventViewDidTapTrack(_: EventView) {
    viewModel.didSelectTrack()
  }

  func eventViewDidTapVideo(_: EventView) {
    viewModel.didSelectVideo()
  }

  func eventView(_: EventView, didSelect url: URL) {
    let attachmentViewController = SFSafariViewController(url: url)
    present(attachmentViewController, animated: true)
  }

  func eventView(_: EventView, playbackPositionFor _: Event) -> PlaybackPosition {
    viewModel.playbackPosition
  }
}

extension EventViewController: AVPlayerViewControllerDelegate {
  func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator _: UIViewControllerTransitionCoordinator) {
    guard let player = playerViewController.player else { return }
    viewModel.willBeginVideoPlayback(with: player)
  }

  func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator _: UIViewControllerTransitionCoordinator) {
    guard let player = playerViewController.player else { return }
    viewModel.didEndVideoPlayback(with: player)
  }
}

private extension EventViewController {
  private var isAdaptive: Bool {
    tableView.style != .insetGrouped
  }

  @objc func didToggleFavorite() {
    viewModel.didToggleFavorite()
  }
}

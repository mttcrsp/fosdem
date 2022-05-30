import RIBs

protocol TrackRouting: ViewableRouting {}

protocol TrackPresentable: Presentable {}

protocol TrackListener: AnyObject {}

final class TrackInteractor: PresentableInteractor<TrackPresentable>, TrackInteractable, TrackPresentableListener {
  weak var router: TrackRouting?
  weak var listener: TrackListener?
}

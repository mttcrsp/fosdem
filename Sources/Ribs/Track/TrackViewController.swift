import RIBs
import UIKit

protocol TrackPresentableListener: AnyObject {}

final class TrackViewController: UIViewController {
  weak var listener: TrackPresentableListener?
}

extension TrackViewController: TrackPresentable {}

extension TrackViewController: TrackViewControllable {}

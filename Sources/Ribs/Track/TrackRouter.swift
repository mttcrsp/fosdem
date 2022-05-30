import RIBs

protocol TrackInteractable: Interactable {}

protocol TrackViewControllable: ViewControllable {}

final class TrackRouter: ViewableRouter<TrackInteractable, TrackViewControllable> {}

extension TrackRouter: TrackRouting {}

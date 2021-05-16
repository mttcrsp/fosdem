import Foundation

struct PlayVideo: Activity {
  static let activityType = "com.mttcrsp.fosdem.PlayVideo"
  let event: Event
  let video: Link
}

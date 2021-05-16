import Foundation

struct ReadAttachment: Activity {
  static let activityType = "com.mttcrsp.fosdem.ReadAttachment"
  let event: Event
  let attachment: Attachment
}

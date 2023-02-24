@testable
import Fosdem
import Foundation

extension Event {
  static func from(_ string: String) throws -> Event {
    try JSONDecoder().decode(Event.self, from: Data(string.utf8))
  }
}

@testable
import Fosdem
import Foundation

final class LiveServiceProviderMock: LiveServiceProvider {
    private(set) var block: ((Timer) -> Void)?
    private(set) var interval: TimeInterval?
    private(set) var repeats: Bool?
    private let timer: Timer

    init(timer: Timer) {
        self.timer = timer
    }

    func scheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) -> Timer {
        self.interval = interval
        self.repeats = repeats
        self.block = block
        return timer
    }
}

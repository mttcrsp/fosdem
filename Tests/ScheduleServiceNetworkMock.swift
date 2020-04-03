@testable
import Fosdem

final class ScheduleServiceNetworkMock: ScheduleServiceNetwork {
    private(set) var request: ScheduleRequest?
    private(set) var completion: ((Result<Schedule, Error>) -> Void)?

    @discardableResult
    func perform(_ request: ScheduleRequest, completion: @escaping (Result<Schedule, Error>) -> Void) -> NetworkServiceTask {
        self.request = request
        self.completion = completion
        return NetworkServiceTaskMock()
    }

    func reset() {
        request = nil
        completion = nil
    }
}

final class ScheduleServiceNetworkAutomaticMock: ScheduleServiceNetwork {
    private(set) var numberOfInvocations = 0

    private let schedule: Schedule

    init(schedule: Schedule) {
        self.schedule = schedule
    }

    @discardableResult
    func perform(_: ScheduleRequest, completion: @escaping (Result<Schedule, Error>) -> Void) -> NetworkServiceTask {
        numberOfInvocations += 1
        completion(.success(schedule))
        return NetworkServiceTaskMock()
    }
}

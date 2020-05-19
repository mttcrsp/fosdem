@testable
import Fosdem
import Foundation

final class CrashServiceReporterMock: CrashServiceReporter {
    private(set) var didPurge = false
    private(set) var didLoad = false

    private let loadReportData: Data?
    private let hasReport: Bool
    private let canEnable: Bool
    private let canPurge: Bool

    init(canEnable: Bool, canPurge: Bool, hasReport: Bool, loadReportData: Data?) {
        self.loadReportData = loadReportData
        self.hasReport = hasReport
        self.canEnable = canEnable
        self.canPurge = canPurge
    }

    func enable() -> Bool {
        canEnable
    }

    func hasPendingCrashReport() -> Bool {
        hasReport
    }

    func purgePendingCrashReport() -> Bool {
        didPurge = true
        return canPurge
    }

    func loadPendingCrashReportData() -> Data! {
        didLoad = true
        return loadReportData
    }
}

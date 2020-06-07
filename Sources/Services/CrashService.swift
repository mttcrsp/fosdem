import CrashReporter

protocol CrashServiceNetwork {
  @discardableResult
  func perform(_ request: JSONBinRequest, completion: @escaping (Result<Void, Error>) -> Void) -> NetworkServiceTask
}

protocol CrashServiceReporter {
  func enable() -> Bool
  func hasPendingCrashReport() -> Bool
  func purgePendingCrashReport() -> Bool
  func loadPendingCrashReportData() -> Data!
}

final class CrashService {
  private let networkService: CrashServiceNetwork
  private let reporter: CrashServiceReporter
  private let secretKey: String

  init?(networkService: CrashServiceNetwork, reporter: CrashServiceReporter = PLCrashReporter(), secretKey: String = Secret.jsonbin) {
    if reporter.enable() {
      self.networkService = networkService
      self.secretKey = secretKey
      self.reporter = reporter
    } else {
      return nil
    }
  }

  var hasPendingReport: Bool {
    reporter.hasPendingCrashReport()
  }

  func purgeReport() {
    _ = reporter.purgePendingCrashReport()
  }

  func uploadReport() {
    if hasPendingReport, let data = reporter.loadPendingCrashReportData() {
      let request = JSONBinRequest(secretKey: secretKey, data: data)
      networkService.perform(request, completion: { _ in })
    }
  }
}

extension PLCrashReporter: CrashServiceReporter {}

extension NetworkService: CrashServiceNetwork {}

@testable
import Fosdem
import Foundation

final class PreloadServiceFileMock: PreloadServiceFile {
    private(set) var oldPath: String?
    private(set) var newPath: String?

    private let moveItemResult: Result<Void, Error>
    private let urlResult: Result<URL, Error>
    private let fileExists: Bool

    init(fileExists: Bool, moveItemResult: Result<Void, Error>, urlResult: Result<URL, Error>) {
        self.moveItemResult = moveItemResult
        self.fileExists = fileExists
        self.urlResult = urlResult
    }

    func fileExists(atPath _: String) -> Bool {
        fileExists
    }

    func moveItem(atPath oldPath: String, toPath newPath: String) throws {
        self.oldPath = oldPath
        self.newPath = newPath

        switch moveItemResult {
        case .success: break
        case let .failure(error): throw error
        }
    }

    func url(for _: FileManager.SearchPathDirectory, in _: FileManager.SearchPathDomainMask, appropriateFor _: URL?, create _: Bool) throws -> URL {
        switch urlResult {
        case let .success(value): return value
        case let .failure(error): throw error
        }
    }
}

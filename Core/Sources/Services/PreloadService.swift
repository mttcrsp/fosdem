import Foundation

protocol PreloadServiceFile {
  func fileExists(atPath path: String) -> Bool
  func copyItem(atPath srcPath: String, toPath dstPath: String) throws
  func url(for directory: FileManager.SearchPathDirectory, in domain: FileManager.SearchPathDomainMask, appropriateFor url: URL?, create shouldCreate: Bool) throws -> URL
  func removeItem(atPath path: String) throws
}

protocol PreloadServiceBundle {
  func path(forResource name: String?, ofType ext: String?) -> String?
}

final class PreloadService {
  enum Error: CustomNSError {
    case resourceNotFound
  }

  private let oldPath: String
  private let newPath: String
  private let bundle: PreloadServiceBundle
  private let fileManager: PreloadServiceFile

  init(bundle: PreloadServiceBundle = Bundle.main, fileManager: PreloadServiceFile = FileManager.default) throws {
    self.fileManager = fileManager
    self.bundle = bundle

    let fileName = "db", fileExtension = "sqlite"
    guard let oldPath = bundle.path(forResource: fileName, ofType: fileExtension) else {
      throw Error.resourceNotFound
    }

    let applicationSupportURL = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    let applicationDatabaseURL = applicationSupportURL.appendingPathComponent(fileName).appendingPathExtension(fileExtension)
    let newPath = applicationDatabaseURL.path

    self.oldPath = oldPath
    self.newPath = newPath
  }

  var databasePath: String {
    newPath
  }

  func removeDatabase() throws {
    try fileManager.removeItem(atPath: newPath)
  }

  func preloadDatabaseIfNeeded() throws {
    if !fileManager.fileExists(atPath: newPath) {
      try fileManager.copyItem(atPath: oldPath, toPath: newPath)
    }
  }
}

extension Bundle: PreloadServiceBundle {}

extension FileManager: PreloadServiceFile {}

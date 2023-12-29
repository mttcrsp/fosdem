final class TrackFormatter {
  func formattedName(from name: String) -> String {
    let devroomSuffix = " devroom"
    if name.hasSuffix(devroomSuffix) {
      return String(name[...name.index(name.endIndex, offsetBy: -devroomSuffix.count)])
    } else {
      return name
    }
  }
}

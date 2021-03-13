public struct Participation: Codable {
  public let personID, eventID: Int

  public init(personID: Int, eventID: Int) {
    self.personID = personID
    self.eventID = eventID
  }
}

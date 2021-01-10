import XCTest

extension XCUIElement {
  var backButton: XCUIElement {
    navigationBars.buttons.firstMatch
  }

  // WORKAROUND: UITableView does not provide APIs to configure the
  // accessibility identifier of swipe actions. The only way to identify a given
  // action is to either use its localized accessibility value (will break when
  // changing locale) or attempt to guess the button to tap based on the
  // elements hierarchy structure (e.g. `buttons[buttons.count - 1]`). I decided
  // to go with the first option, routing all calls to this method to simplify
  // refactoring later on.
  func tapTrailingAction(withIdentifier identifier: String) {
    swipeLeft()
    buttons[identifier].tap()
  }
}

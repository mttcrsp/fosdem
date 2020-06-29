import XCTest

final class EventControllerTests: XCTestCase {
  func testFavorite() {
    let app = XCUIApplication()
    app.launchEnvironment = ["RESET_DEFAULTS": "1"]
    app.launch()

    runActivity(named: "Favorite event") {
      app.searchButton.tap()
      app.day1TrackStaticText.tap()
      app.day1TrackEventStaticText.tap()
      app.favoriteEventButton.tap()
      XCTAssert(app.unfavoriteEventButton.exists)
    }

    runActivity(named: "Display in Agenda") {
      app.terminate()
      app.launchEnvironment = [:]
      app.launch()
      app.agendaButton.tap()
      wait { app.cells.count == 1 }
    }

    runActivity(named: "Unfavorite event") {
      app.searchButton.tap()
      app.day1TrackStaticText.tap()
      app.day1TrackEventStaticText.tap()
      app.unfavoriteEventButton.tap()
      XCTAssert(app.favoriteEventButton.exists)
    }
  }

  func testVideo() {
    let app = XCUIApplication()
    app.launchEnvironment = ["RESET_DEFAULTS": "1"]
    app.launch()

    let pauseButton = app.buttons["Play/Pause"]
    let playButton = app.buttons["Play/Pause"]
    let doneButton = app.buttons["Done"]

    let isPlaying: () -> Bool = {
      playButton.exists && playButton.isEnabled
    }

    let hasPlayed1Second: () -> Bool = {
      if let seconds = app.staticTexts["Time Elapsed"].secondsValue, seconds >= 1 {
        return true
      } else {
        return false
      }
    }

    let isLast15Seconds: () -> Bool = {
      if let seconds = app.staticTexts["Time Remaining"].secondsValue, seconds <= 15 {
        return true
      } else {
        return false
      }
    }

    runActivity(named: "Play video") {
      app.searchButton.tap()
      app.day1TrackStaticText.tap()
      app.day1TrackEventStaticText.tap()
      app.buttons["play"].tap()

      // WORKAROUND: Video playback sometimes fails to start in poor network
      // conditions. Dismiss the player view controller and attempting its
      // presentation again sometimes fixes the issue.
      var succeeded = false
      for _ in 1 ... 3 where !succeeded {
        let expectation = XCTNSPredicateExpectation {
          isPlaying() && hasPlayed1Second()
        }
        let result = XCTWaiter().wait(for: [expectation], timeout: 10)
        if result == .completed {
          succeeded = true
        } else {
          doneButton.tap()
          app.buttons["play"].tap()
        }
      }

      if !succeeded {
        return XCTFail("Failed to start video playback")
      }
    }

    runActivity(named: "Resume video") {
      // Make sure that playback controls are visible before tapping done
      if !doneButton.exists {
        app.tap()
      }
      doneButton.tap()

      app.buttons["resume"].tap()

      if !doneButton.exists {
        app.tap()
      }

      var succeeded = false
      for _ in 1 ... 3 where !succeeded {
        let expectation = XCTNSPredicateExpectation(predicate: isPlaying)
        let result = XCTWaiter().wait(for: [expectation], timeout: 10)
        if result == .completed {
          succeeded = true
        } else {
          doneButton.tap()
          app.buttons["resume"].tap()
        }
      }

      if !succeeded {
        return XCTFail("Failed to start video playback")
      }
    }

    runActivity(named: "Replay video") {
      if !playButton.exists {
        app.tap()
      }
      pauseButton.tap()

      while !isLast15Seconds() {
        app.buttons["Skip Forward"].tap()
      }

      // Play the video to completion so that it will automatically dismiss
      playButton.tap()
      wait(timeout: 20) { app.buttons["replay"].exists }
    }

    app.backButton.tap()
  }

  func testAttachment() {
    let app = XCUIApplication()
    app.launchEnvironment = ["RESET_DEFAULTS": "1"]
    app.launch()

    let attachmentButton = app.links["Jail Orchestration (Slides)"]

    runActivity(named: "Open event") {
      app.staticTexts["BSD"].tap()
      app.staticTexts["Orchestrating jails with nomad and pot"].tap()
      wait { app.eventTable.exists }
    }

    runActivity(named: "Open attachment") {
      app.eventTable.swipeUp()
      attachmentButton.tap()
      wait { app.staticTexts["Jail_orchestration"].exists }
    }

    runActivity(named: "Close attachment") {
      app.otherElements["TopBrowserBar"].buttons.firstMatch.tap()
      wait { attachmentButton.exists }
    }
  }
}

extension XCUIApplication {
  var eventTable: XCUIElement {
    tables["event"]
  }

  var favoriteEventButton: XCUIElement {
    buttons["favorite"]
  }

  var unfavoriteEventButton: XCUIElement {
    buttons["unfavorite"]
  }
}

private extension XCUIElement {
  var stringValue: String? {
    value as? String
  }

  var secondsValue: Int? {
    let value = stringValue?.filter { character in
      character.isDecimalDigit || character == ":"
    }

    let components = value?.components(separatedBy: ":")
    if let components = components, components.count == 2,
      let minutes = Int(components[0]),
      let seconds = Int(components[1]) {
      return (minutes * 60) + seconds
    } else {
      return nil
    }
  }
}

private extension Character {
  var isDecimalDigit: Bool {
    unicodeScalars.allSatisfy(CharacterSet.decimalDigits.contains)
  }
}

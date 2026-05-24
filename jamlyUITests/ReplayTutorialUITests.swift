import XCTest

/// Vérifie que le bouton "Replay tutorial" dans Settings re-déclenche le tutoriel.
final class ReplayTutorialUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Loggé, sans flag tutorial actif → atterrissage direct sur MainTabView sans overlay.
        app.launchArguments = [
            "-UITEST",
            "-UITEST-MOCK-API",
            "-UITEST-AUTH",
            "-UITEST-RESET-TUTORIAL"
        ]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testReplayTutorialFromSettings() throws {
        // 1. MainTabView présent, pas de tutoriel
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["Ton feed"].exists,
                       "Tutoriel affiché alors que RESET-TUTORIAL est actif")

        // 2. Naviguer vers Profile (5e tab)
        let tabBar = app.tabBars.firstMatch
        let profileTab = tabBar.buttons.element(boundBy: 4)
        XCTAssertTrue(profileTab.waitForExistence(timeout: 5))
        profileTab.tap()

        // 3. Ouvrir settings
        let settingsButton = app.buttons["profile.settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5),
                      "Bouton settings introuvable sur ProfileView")
        settingsButton.tap()

        // 4. Tap Replay tutorial
        let replay = app.buttons["settings.replayTutorialButton"]
        XCTAssertTrue(replay.waitForExistence(timeout: 5))
        replay.tap()

        // 5. Tutoriel apparaît
        XCTAssertTrue(app.staticTexts["Ton feed"].waitForExistence(timeout: 5),
                      "Tutoriel non re-déclenché après tap sur Replay")
        XCTAssertTrue(app.buttons["tutorial.nextButton"].exists)
    }
}

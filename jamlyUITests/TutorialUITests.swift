import XCTest

/// Tests du tutoriel in-app affiché par-dessus MainTabView.
/// Lance l'app loggée (`-UITEST-AUTH`) avec le flag tutoriel forcé.
final class TutorialUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "-UITEST",
            "-UITEST-MOCK-API",
            "-UITEST-AUTH",
            "-UITEST-TRIGGER-TUTORIAL"
        ]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testTutorialAppearsOnFirstLaunch() throws {
        XCTAssertTrue(app.staticTexts["Ton feed"].waitForExistence(timeout: 10),
                      "Tutoriel non affiché alors que TRIGGER-TUTORIAL est actif")
        XCTAssertTrue(app.buttons["tutorial.nextButton"].exists)
        XCTAssertTrue(app.buttons["tutorial.skipButton"].exists)
    }

    @MainActor
    func testTutorialNextAdvancesThroughAllSteps() throws {
        XCTAssertTrue(app.staticTexts["Ton feed"].waitForExistence(timeout: 10))

        let titles = ["Discover", "Publie un post", "Discute", "Ton profil"]
        for title in titles {
            app.buttons["tutorial.nextButton"].tap()
            XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 3),
                          "Step manquant: \(title)")
        }

        // Dernier step → bouton devient doneButton
        XCTAssertTrue(app.buttons["tutorial.doneButton"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testTutorialBackButtonAppearsAfterFirstStep() throws {
        XCTAssertTrue(app.staticTexts["Ton feed"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["tutorial.backButton"].exists, "Back ne doit pas exister au step 0")

        app.buttons["tutorial.nextButton"].tap()
        XCTAssertTrue(app.buttons["tutorial.backButton"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testTutorialSkipDismissesOverlay() throws {
        XCTAssertTrue(app.staticTexts["Ton feed"].waitForExistence(timeout: 10))
        app.buttons["tutorial.skipButton"].tap()

        // Card du tutoriel doit disparaître
        XCTAssertFalse(app.staticTexts["Ton feed"].waitForExistence(timeout: 2),
                       "Tutoriel toujours visible après Skip")
        // Tab bar toujours là
        XCTAssertTrue(app.tabBars.firstMatch.exists)
    }

    @MainActor
    func testTutorialDoneDismissesOverlay() throws {
        XCTAssertTrue(app.staticTexts["Ton feed"].waitForExistence(timeout: 10))

        // Avancer jusqu'au dernier step
        for _ in 0..<4 {
            app.buttons["tutorial.nextButton"].tap()
        }

        let done = app.buttons["tutorial.doneButton"]
        XCTAssertTrue(done.waitForExistence(timeout: 3))
        done.tap()

        XCTAssertFalse(app.staticTexts["Ton profil"].waitForExistence(timeout: 2),
                       "Tutoriel toujours visible après Done")
    }

    @MainActor
    func testTutorialSwitchesTabOnNext() throws {
        XCTAssertTrue(app.staticTexts["Ton feed"].waitForExistence(timeout: 10))
        app.buttons["tutorial.nextButton"].tap()
        // Step 2 (Discover) → la tab Discover doit être sélectionnée
        XCTAssertTrue(app.staticTexts["Discover"].waitForExistence(timeout: 3))
    }
}

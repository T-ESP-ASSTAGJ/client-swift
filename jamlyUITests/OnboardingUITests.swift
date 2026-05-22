import XCTest

final class OnboardingUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "-UITEST",
            "-UITEST-MOCK-API",
            "-UITEST-RESET-ONBOARDING",
            "-UITEST-LOGGED-OUT"
        ]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testOnboardingFirstSlideVisible() throws {
        XCTAssertTrue(app.staticTexts["Bienvenue sur Jamly"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Le réseau social qui fait vibrer ta musique."].exists)
    }

    @MainActor
    func testOnboardingNextButtonAdvancesSlides() throws {
        XCTAssertTrue(app.staticTexts["Bienvenue sur Jamly"].waitForExistence(timeout: 5))

        let next = app.buttons["onboarding.nextButton"]
        XCTAssertTrue(next.exists)
        next.tap()

        XCTAssertTrue(app.staticTexts["Partage tes coups de cœur"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testOnboardingSwipeThroughAllSlides() throws {
        XCTAssertTrue(app.staticTexts["Bienvenue sur Jamly"].waitForExistence(timeout: 5))

        let titles = [
            "Partage tes coups de cœur",
            "Découvre de nouveaux sons",
            "Reste connecté"
        ]
        for title in titles {
            app.swipeLeft()
            XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 3), "Slide manquante: \(title)")
        }
    }

    @MainActor
    func testOnboardingCompletionNavigatesToLogin() throws {
        XCTAssertTrue(app.staticTexts["Bienvenue sur Jamly"].waitForExistence(timeout: 5))

        for _ in 0..<3 {
            app.buttons["onboarding.nextButton"].tap()
        }

        let done = app.buttons["onboarding.doneButton"]
        XCTAssertTrue(done.waitForExistence(timeout: 3))
        done.tap()

        XCTAssertTrue(app.staticTexts["JAMLY."].waitForExistence(timeout: 5))
    }
}

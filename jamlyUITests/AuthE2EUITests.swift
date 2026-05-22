import XCTest

/// E2E complet: onboarding → login → OTP → feed.
/// Utilise MockURLProtocol (launchArg `-UITEST-MOCK-API`).
final class AuthE2EUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helpers

    private func typeOTP(_ code: String) {
        // Focus se place sur le 1er digit à l'apparition.
        // typeText (sans tap sur chaque field) déclenche le passage auto.
        let first = app.textFields["otp.digit.0"]
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        first.tap()
        for char in code {
            app.typeText(String(char))
        }
    }

    // MARK: - Tests

    @MainActor
    func testCompleteLoginFlowReachesMainTabs() throws {
        app.launchArguments = [
            "-UITEST",
            "-UITEST-MOCK-API",
            "-UITEST-SKIP-ONBOARDING",
            "-UITEST-LOGGED-OUT"
        ]
        app.launch()

        // 1. Login screen
        let email = app.textFields["login.emailField"]
        XCTAssertTrue(email.waitForExistence(timeout: 5))
        email.tap()
        email.typeText("test@jamly.com")
        app.buttons["login.continueButton"].tap()

        // 2. OTP screen
        XCTAssertTrue(app.staticTexts["Vérification"].waitForExistence(timeout: 5))
        typeOTP("123456")

        // 3. Verify → feed
        let verifyButton = app.buttons["otp.verifyButton"]
        if verifyButton.isEnabled {
            verifyButton.tap()
        }

        // 4. MainTabView présent
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Tab bar absente après login")
        XCTAssertTrue(app.buttons["Home"].exists || tabBar.buttons.element(boundBy: 0).exists)
    }

    @MainActor
    func testAuthenticatedLaunchShowsTabBar() throws {
        app.launchArguments = [
            "-UITEST",
            "-UITEST-MOCK-API",
            "-UITEST-AUTH"
        ]
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10))
    }

    @MainActor
    func testFullFlowFromOnboarding() throws {
        app.launchArguments = [
            "-UITEST",
            "-UITEST-MOCK-API",
            "-UITEST-RESET-ONBOARDING",
            "-UITEST-LOGGED-OUT"
        ]
        app.launch()

        // Onboarding
        XCTAssertTrue(app.staticTexts["Bienvenue sur Jamly"].waitForExistence(timeout: 5))
        for _ in 0..<3 {
            app.buttons["onboarding.nextButton"].tap()
        }
        app.buttons["onboarding.doneButton"].tap()

        // Login
        let email = app.textFields["login.emailField"]
        XCTAssertTrue(email.waitForExistence(timeout: 5))
        email.tap()
        email.typeText("user@example.com")
        app.buttons["login.continueButton"].tap()

        // OTP
        XCTAssertTrue(app.staticTexts["Vérification"].waitForExistence(timeout: 5))
        typeOTP("000000")
        if app.buttons["otp.verifyButton"].isEnabled {
            app.buttons["otp.verifyButton"].tap()
        }

        // Feed
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
    }
}

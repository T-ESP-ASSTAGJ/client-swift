import XCTest

final class LoginUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "-UITEST",
            "-UITEST-MOCK-API",
            "-UITEST-SKIP-ONBOARDING",
            "-UITEST-LOGGED-OUT"
        ]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testLoginViewIsDisplayed() throws {
        XCTAssertTrue(app.staticTexts["JAMLY."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Welcome to"].exists)
    }

    @MainActor
    func testContinueButtonDisabledWithInvalidEmail() throws {
        let email = app.textFields["login.emailField"]
        XCTAssertTrue(email.waitForExistence(timeout: 5))
        email.tap()
        email.typeText("not-an-email")

        let button = app.buttons["login.continueButton"]
        XCTAssertTrue(button.exists)
        XCTAssertFalse(button.isEnabled)
    }

    @MainActor
    func testContinueButtonEnabledWithValidEmail() throws {
        let email = app.textFields["login.emailField"]
        XCTAssertTrue(email.waitForExistence(timeout: 5))
        email.tap()
        email.typeText("user@example.com")

        let button = app.buttons["login.continueButton"]
        XCTAssertTrue(button.exists)
        XCTAssertTrue(button.isEnabled)
    }

    @MainActor
    func testSubmitEmailNavigatesToOtpScreen() throws {
        let email = app.textFields["login.emailField"]
        XCTAssertTrue(email.waitForExistence(timeout: 5))
        email.tap()
        email.typeText("test@jamly.com")

        app.buttons["login.continueButton"].tap()

        XCTAssertTrue(app.staticTexts["Vérification"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["test@jamly.com"].exists)
    }
}

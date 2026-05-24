import XCTest

/// Flow signup complet : login → OTP → ProfileSetup (username vide) → tutoriel auto-déclenché.
final class SignupFlowUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "-UITEST",
            "-UITEST-MOCK-API",
            "-UITEST-SKIP-ONBOARDING",
            "-UITEST-LOGGED-OUT",
            "-UITEST-NEEDS-PROFILE-SETUP"
        ]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    private func typeOTP(_ code: String) {
        let first = app.textFields["otp.digit.0"]
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        first.tap()
        for char in code {
            app.typeText(String(char))
        }
    }

    @MainActor
    func testSignupTriggersTutorialAfterProfileSetup() throws {
        // 1. Login
        let email = app.textFields["login.emailField"]
        XCTAssertTrue(email.waitForExistence(timeout: 5))
        email.tap()
        email.typeText("newuser@jamly.com")
        app.buttons["login.continueButton"].tap()

        // 2. OTP
        XCTAssertTrue(app.staticTexts["Vérification"].waitForExistence(timeout: 5))
        typeOTP("123456")
        let verify = app.buttons["otp.verifyButton"]
        if verify.isEnabled {
            verify.tap()
        }

        // 3. ProfileSetup parce que username vide
        let username = app.textFields["profileSetup.usernameField"]
        XCTAssertTrue(username.waitForExistence(timeout: 10), "ProfileSetup non affiché")
        username.tap()
        username.typeText("newuser_test")
        app.buttons["profileSetup.continueButton"].tap()

        // 4. Step photo → Skip
        let skip = app.buttons["profileSetup.skipButton"]
        XCTAssertTrue(skip.waitForExistence(timeout: 5))
        skip.tap()

        // 5. Tutoriel déclenché automatiquement à l'arrivée sur MainTabView
        XCTAssertTrue(app.staticTexts["Ton feed"].waitForExistence(timeout: 10),
                      "Tutoriel non déclenché après signup")
    }
}

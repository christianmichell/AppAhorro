import XCTest

final class AppAhorroUITests: XCTestCase {
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Resumen"].exists)
    }
}

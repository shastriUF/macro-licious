//
//  macroliciousUITests.swift
//  macroliciousUITests
//
//  Created by Aniruddha Shastri on 2/15/26.
//

import XCTest

final class macroliciousUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testDiaryShowsEntryModeSegments() throws {
        let app = XCUIApplication()
        app.launch()

        openMealsTab(in: app)

        XCTAssertTrue(app.buttons["Library"].exists)
        XCTAssertTrue(app.buttons["Manual"].exists)
    }

    @MainActor
    func testManualModeShowsManualFieldsAndDisablesAddWithoutValidInput() throws {
        let app = XCUIApplication()
        app.launch()

        openMealsTab(in: app)

        let manualButton = app.buttons["Manual"]
        XCTAssertTrue(manualButton.waitForExistence(timeout: 5))
        manualButton.tap()

        let ingredientNameField = app.textFields["Ingredient name"]
        XCTAssertTrue(ingredientNameField.waitForExistence(timeout: 5))

        let addButton = app.buttons["Add Meal Log Entry"]
        XCTAssertTrue(addButton.exists)
        XCTAssertFalse(addButton.isEnabled)
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }

    private func openMealsTab(in app: XCUIApplication) {
        let mealsTab = app.tabBars.buttons["Meals"]
        XCTAssertTrue(mealsTab.waitForExistence(timeout: 5))
        mealsTab.tap()
    }
}

//
//  Screenshots.swift
//  Screenshots
//
//  Created by Benjamin Erhart on 09.03.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import XCTest

class Screenshots: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testScreenshots() throws {

        // UI tests must launch the application that they test.
        let app = XCUIApplication()
		setupSnapshot(app)
        app.launch()

		snapshot("0-Main")

		let navBar = app.navigationBars["Orbot"]

		navBar.buttons["open_close_log"].tap()

		snapshot("1-Log")

		navBar/*@START_MENU_TOKEN@*/.buttons["open_close_log"]/*[[".buttons[\"Open or Close Log\"]",".buttons[\"open_close_log\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()


		navBar.buttons["settings_menu"].tap()
		app.collectionViews.buttons["settings"].tap()

		snapshot("2-Settings")

		app.buttons["close_settings"].tap()

		navBar.buttons["settings_menu"].tap()
		app.collectionViews.buttons["auth_cookies"].tap()

		snapshot("3-Auth-Cookies")

		app.buttons["close_auth_cookies"].tap()

		app.buttons["bridge_configuration"].tap()

		snapshot("4-Bridge-Configuration")

		app.tables.cells["transport_3"].tap()

		snapshot("5-Custom-Bridges")

        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

//    func testLaunchPerformance() throws {
//        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
//            // This measures how long it takes to launch your application.
//            measure(metrics: [XCTApplicationLaunchMetric()]) {
//                XCUIApplication().launch()
//            }
//        }
//    }
}

//
//  AppDelegate.swift
//  Orbot Mac
//
//  Created by Benjamin Erhart on 11.08.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {




	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}

	func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
		return true
	}

	@IBAction func openMain(_ sender: Any) {
		frontOrOpen("MainWindowController", windowId: "MainWindow")
	}

	@IBAction func openLog(_ sender: Any) {
		frontOrOpen("LogWindowController", windowId: "LogWindow")
	}


	// MARK: Private Methods

	private func frontOrOpen(_ controllerId: String, windowId: String) {
		if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == windowId }) {
			window.orderFrontRegardless()
			window.makeKey()
		}
		else {
			(NSStoryboard.main?.instantiateController(withIdentifier: controllerId) as? NSWindowController)?.showWindow(self)
		}
	}
}

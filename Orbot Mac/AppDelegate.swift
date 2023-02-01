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
		Settings.setPtStateLocation()

#if DEBUG
		SharedUtils.addScreenshotDummies()
#endif

		NSApp.mainMenu = translate(NSApp.mainMenu)
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}

	func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
		return true
	}


	// MARK: Private Methods

	private func translate(_ menu: NSMenu?) -> NSMenu? {
		guard let menu = menu else {
			return nil
		}

		let newMenu = NSMenu(title: translate(menu.title))

		for item in menu.items {
			menu.removeItem(item)
			newMenu.addItem(translate(item))
		}

		return newMenu
	}

	private func translate(_ item: NSMenuItem) -> NSMenuItem {
		item.title = translate(item.title)

		item.submenu = translate(item.submenu)

		return item
	}

	private func translate(_ title: String) -> String {
		if let localized = L10n.menu[title]?(), !localized.isEmpty {
			return localized
		}

		return title
	}
}

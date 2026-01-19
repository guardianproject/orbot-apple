//
//  AppDelegate.swift
//  Orbot
//
//  Created by Benjamin Erhart on 20.05.20.
//  Copyright © 2020 - 2026 Guardian Project. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?


	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
	{
		Settings.stateLocation = FileManager.default.ptDir!

		// No PT support on iOS, currently. Reset any chosen transports from
		// earlier versions.
		// TODO: Remove this, once PT support is back!
		Settings.transport = .none
		Settings.smartConnect = false

		UIBarButtonItem.appearance().tintColor = .label
		UITableViewCell.appearance().tintColor = .label
		UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = .label
		UITableView.appearance().backgroundColor = .black2
		UITableViewCell.appearance().backgroundColor = .black3
		UISwitch.appearance(whenContainedInInstancesOf: [BaseFormViewController.self]).onTintColor = .darkGreen

#if DEBUG
		SharedUtils.addScreenshotDummies()
#endif

//		Task {
//			try await Task.sleep(nanoseconds: 1_000_000_000)
//
//			await UIApplication.shared.open(URL(string: "orbot:request/token?app-id=foobar&need-bypass=true")!)
//
//			try await Task.sleep(nanoseconds: 1_000_000_000)
//
//			RemoteControl.shared.workQueue()
//		}

		return true
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		VpnManager.shared.reload()
	}

	func application(_ application: UIApplication,
					 continue userActivity: NSUserActivity,
					 restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
	{
		guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
			  let url = userActivity.webpageURL
		else {
			return false
		}

		if RemoteControl.shared.evaluate(url: url) {
			// Call this explicitly, when we're already in the foreground. (iPad multitasking!)
			if UIApplication.shared.applicationState == .active {
				RemoteControl.shared.workQueue()
			}

			return true
		}

		return false
	}

	func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool
	{
		return RemoteControl.shared.evaluate(url: url)
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		RemoteControl.shared.workQueue()
	}
}

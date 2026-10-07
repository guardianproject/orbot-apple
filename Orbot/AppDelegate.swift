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
//			try await Task.sleep(nanoseconds: 1 * NSEC_PER_SEC)
//
//			await UIApplication.shared.open(URL(string: "orbot:request/token?app-id=foobar&need-bypass=true")!)
//
//			try await Task.sleep(nanoseconds: 1 * NSEC_PER_SEC)
//
//			RemoteControl.shared.workQueue()
//		}

		return true
	}
}

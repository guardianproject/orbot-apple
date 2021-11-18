//
//  AppDelegate.swift
//  Orbot
//
//  Created by Benjamin Erhart on 20.05.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import UIKit
import NetworkExtension
import IPtProxy

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
	{
		UIView.appearance().tintColor = .init(named: "DarkGreen")

		return true
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		VpnManager.shared.reload()
	}

	func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool
	{
		guard let urlc = URLComponents(url: url, resolvingAgainstBaseURL: true),
			  let vc = (window?.rootViewController as? UINavigationController)?.viewControllers.first as? MainViewController
		else {
			return false
		}

		switch urlc.path {
		case "show":
			// Dummy path so other apps can just start this one.
			break

		case "show.bridges":
			vc.changeBridge()

		case "show.auth":
			vc.showAuth()

		case "add.auth":
			let url = urlc.queryItems?.first(where: { $0.name == "url" })?.value
			let key = urlc.queryItems?.first(where: { $0.name == "key" })?.value

			vc.showAuth().addKey(URL(string: url ?? ""), key)

		default:
			return false
		}

		return true
	}
}

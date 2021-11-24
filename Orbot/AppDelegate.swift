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

#if DEBUG
		addScreenshotDummies()
#endif

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

#if DEBUG
	private func addScreenshotDummies() {
		guard Config.screenshotMode, let authDir = FileManager.default.torAuthDir else {
			return
		}

		do {
			try "6gk626a5xm3gdyrbezfhiptzegvvc62c3k6y3xbelglgtgqtbai5liqd:descriptor:x25519:EJOYJMYKNS6TYTQ2RSPZYBSBR3RUZA5ZKARKLF6HXVXHTIV76UCQ"
				.write(to: authDir.appendingPathComponent("6gk626a5xm3gdyrbezfhiptzegvvc62c3k6y3xbelglgtgqtbai5liqd.auth_private"),
					   atomically: true, encoding: .utf8)

			try "jtb2cwibhkok4f2xejfqbsjb2xcrwwcdj77bjvhofongraxvumudyoid:descriptor:x25519:KC2VJ5JLZ5QLAUUZYMRO4R3JSOYM3TBKXDUMAS3D5BEI5IPYUI4A"
				.write(to: authDir.appendingPathComponent("jtb2cwibhkok4f2xejfqbsjb2xcrwwcdj77bjvhofongraxvumudyoid.auth_private"),
					   atomically: true, encoding: .utf8)

			try "pqozr7dey5yellqfwzjppv4q25zbzbwligib7o7g5s6bvrltvy3lfdid:descriptor:x25519:ZHXT5IO2OMJKH3HKPDYDNNXXIPJCXR5EG6MGLQNC56GAF2C75I5A"
				.write(to: authDir.appendingPathComponent("pqozr7dey5yellqfwzjppv4q25zbzbwligib7o7g5s6bvrltvy3lfdid.auth_private"),
					   atomically: true, encoding: .utf8)
		}
		catch {
			print(error)
		}
	}
#endif
}

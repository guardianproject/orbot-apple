//
//  AppDelegate.swift
//  Orbot
//
//  Created by Benjamin Erhart on 20.05.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import UIKit
import IPtProxyUI

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

//		DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//			UIApplication.shared.open(URL(string: "orbot:request/token?app-id=foobar&need-bypass=true")!)
//		}

		return true
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		VpnManager.shared.reload()
	}

	func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
	{
		guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
			  let url = userActivity.webpageURL
		else {
			return false
		}

		return handle(url: url)
	}

	func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool
	{
		return handle(url: url)
	}


	// MARK: Private Methods

	private func handle(url: URL) -> Bool {
		guard let urlc = URLComponents(url: url, resolvingAgainstBaseURL: true),
			  let navC = window?.rootViewController as? UINavigationController,
			  let vc = navC.viewControllers.first as? MainViewController
		else {
			return false
		}

		// Allow "/" (slash) or "." (period, legacy) as separators.
		var pc: ArraySlice<String.SubSequence> = urlc.path.lowercased().split { $0 == "/" || $0 == "." }[...]

		// Remove "rc" pseudo-folder. (From universal link, e.g. "https://orbot.app/rc/start")
		if pc.first == "rc" {
			pc = pc.dropFirst()
		}

		switch pc.joined(separator: "/") {
		case "show":
			// Dummy path so other apps can just start this one.
			navC.dismiss(animated: true)

		case "start":
			navC.dismiss(animated: true) {
				SharedUtils.control(startOnly: true)
			}

		case "show/settings":
			navC.dismiss(animated: true) {
				vc.showSettings()
			}

		case "show/bridges":
			navC.dismiss(animated: true) {
				vc.changeBridges()
			}

		case "show/auth":
			navC.dismiss(animated: true) {
				vc.showAuth()
			}

		case "add/auth":
			navC.dismiss(animated: true) {
				let url = urlc.queryItems?.first(where: { $0.name == "url" })?.value
				let key = urlc.queryItems?.first(where: { $0.name == "key" })?.value

				vc.showAuth().addKey(URL(string: url ?? ""), key)
			}

		case "request/token":
			navC.dismiss(animated: true) {
				let appId = urlc.queryItems?.first(where: { $0.name == "app-id" })?.value
				let appName = urlc.queryItems?.first(where: { $0.name == "app-name" })?.value
				let needsBypass = Bool(urlc.queryItems?.first(where: { $0.name == "need-bypass" })?.value ?? "") ?? false
				let callback = urlc.queryItems?.first(where: { $0.name == "callback" })?.value

				guard let appId = appId,
					  !appId.isEmpty
				else {
					let message = NSLocalizedString("Another app requested an API access token.", comment: "")
					+ "\n\n"
					+ NSLocalizedString("It didn't provide a valid app identifier.", comment: "")
					+ "\n\n"
					+ NSLocalizedString("Please report this error to the requesting app's developers.", comment: "")
					+ "\n"
					+ NSLocalizedString("That app will be unable to access Orbot's API as long as this is not fixed.", comment: "")

					AlertHelper.present(vc, message: message)

					return
				}

				var urlc: URLComponents? = nil

				if let callback = callback {
					urlc = URLComponents(string: callback)
				}

				let apiVc = vc.showApiAccess()

				let completion = { (token: ApiToken?) in
					if let token = token {
						if urlc?.queryItems == nil {
							urlc?.queryItems = []
						}

						urlc?.queryItems?.append(URLQueryItem(name: "token", value: token.key))
					}

					let success = { (success: Bool) in
						if !success && token != nil {
							let message = NSLocalizedString("Another app requested an API access token.", comment: "")
							+ "\n\n"
							+ NSLocalizedString("We could not return to that app, because it didn't provide a valid callback URL.", comment: "")
							+ "\n\n"
							+ NSLocalizedString("The API access token was copied to your clipboard.", comment: "")
							+ "\n"
							+ NSLocalizedString("Go back to the requesting app and paste the token in the appropriate dialog.", comment: "")

							AlertHelper.present(vc, message: message)
						}
					}

					guard let url = urlc?.url else {
						success(false)

						return
					}

					UIApplication.shared.open(url, completionHandler: success)
				}

				apiVc.addToken(appId, appName, needsBypass, completion)
			}

		default:
			return false
		}

		return true
	}
}

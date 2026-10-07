//
//  SceneDelegate.swift
//  Orbot
//
//  Created by Benjamin Erhart on 02.10.26.
//  Copyright © 2026 Guardian Project. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

	var window: UIWindow?


	func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
			   options connectionOptions: UIScene.ConnectionOptions
	) {
		handle(connectionOptions.userActivities)

		handle(connectionOptions.urlContexts.map({ $0.url }))
	}

	func sceneWillEnterForeground(_ scene: UIScene) {
		Task {
			await VpnManager.shared.reload()
		}
	}

	func sceneDidBecomeActive(_ scene: UIScene) {
		RemoteControl.shared.workQueue()
	}

	func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
		handle([userActivity])
	}

	func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
		handle(URLContexts.map({ $0.url }))
	}


	// MARK: Private Methods

	private func handle(_ userActivities: Set<NSUserActivity>) {
		handle(userActivities.compactMap({
			$0.activityType == NSUserActivityTypeBrowsingWeb ? $0.webpageURL : nil
		}))
	}

	private func handle(_ urls: [URL]) {
		var success = false

		for url in urls {
			success = RemoteControl.shared.evaluate(url: url) || success
		}

		// Call this explicitly, when we're already in the foreground. (iPad multitasking!)
		if success && UIApplication.shared.applicationState == .active {
			RemoteControl.shared.workQueue()
		}
	}
}

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


	func sceneWillEnterForeground(_ scene: UIScene) {
		Task {
			await VpnManager.shared.reload()
		}
	}

	func sceneDidBecomeActive(_ scene: UIScene) {
		RemoteControl.shared.workQueue()
	}
}

//
//  UIApplication+Helpers.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 21.03.22.
//

import SwiftUI

extension UIApplication {

    var currentKeyWindow: UIWindow? {
        connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .filter{ $0.isKeyWindow }
            .first
    }

    var rootVc: UITabBarController? {
        currentKeyWindow?.rootViewController as? UITabBarController
    }

	var mainVc: MainViewController? {
		(rootVc?.viewControllers?.first as? UINavigationController)?.viewControllers.first as? MainViewController
	}
}

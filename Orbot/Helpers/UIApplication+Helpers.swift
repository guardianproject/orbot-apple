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

    var rootViewController: UIViewController? {
        currentKeyWindow?.rootViewController
    }
}

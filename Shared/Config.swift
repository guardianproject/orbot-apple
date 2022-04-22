//
//  Config.swift
//  Orbot
//
//  Created by Benjamin Erhart on 20.05.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import Foundation

extension Config {

    class var extBundleId: String {
        __extBundleId as String
    }

	class var contentBlockerBundleId: String {
		__contentBlockerBundleId as String
	}

    class var groupId: String {
        __groupId as String
    }

	class var webserverPort: Int {
		15182
	}

#if DEBUG
	/**
	 Simulates a running Network Extension to get nice screenshots.

	 NEVER EVER remove the `#if DEBUG` condition around this and any code using this.

	 Should positively never end up in production code!
	 */
	class var screenshotMode: Bool {
		UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT")
	}

	/**
	 Show VPN Log, Leaf Log and Leaf Configuration segments in log view for debugging.
	 */
	class var extendedLogging: Bool {
		!screenshotMode
	}
#endif
}

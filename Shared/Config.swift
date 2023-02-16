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
	 Show the Snowflake Proxy experimental button.
	 */
	class var snowflakeProxyExperiment: Bool {
		!screenshotMode && true
	}

	/**
	 Show VPN Log, Leaf Log, Leaf Configuration and Webserver log segments in log view for debugging.
	 */
	class var extendedLogging: Bool {
		!screenshotMode && true
	}
#else
	class var screenshotMode: Bool {
		false
	}
#endif

}

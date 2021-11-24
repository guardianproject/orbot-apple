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
        return __extBundleId as String
    }

    class var groupId: String {
        return __groupId as String
    }

#if DEBUG
	/**
	 Simulates a running Network Extension to get nice screenshots.

	 NEVER EVER remove the `#if DEBUG` condition around this and any code using this.

	 Should positively never end up in production code!
	 */
	class var screenshotMode: Bool {
		return false
	}
#endif
}

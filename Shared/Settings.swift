//
//  Settings.swift
//  Orbot
//
//  Created by Benjamin Erhart on 10.11.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import Foundation
import IPtProxyUI

class Settings: IPtProxyUI.Settings {

	class override var defaults: UserDefaults? {
		UserDefaults(suiteName: Config.groupId)
	}

	open class var entryNodes: String? {
		get {
			defaults?.string(forKey: "entry_nodes")
		}
		set {
			defaults?.set(newValue, forKey: "entry_nodes")
		}
	}

	open class var exitNodes: String? {
		get {
			defaults?.string(forKey: "exit_nodes")
		}
		set {
			defaults?.set(newValue, forKey: "exit_nodes")
		}
	}

	open class var excludeNodes: String? {
		get {
			defaults?.string(forKey: "exclude_nodes")
		}
		set {
			defaults?.set(newValue, forKey: "exclude_nodes")
		}
	}

	open class var strictNodes: Bool {
		get {
			defaults?.bool(forKey: "strict_nodes") ?? false
		}
		set {
			defaults?.set(newValue, forKey: "strict_nodes")
		}
	}
}

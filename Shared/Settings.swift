//
//  Settings.swift
//  Orbot
//
//  Created by Benjamin Erhart on 10.11.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import Foundation
import IPtProxyUI
import CoreMedia

class Settings: IPtProxyUI.Settings {

	enum BlockerSourceType: String {

		case chromiumHsts = "chromium-hsts"
	}

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

	class var advancedTorConf: [String]? {
		get {
			defaults?.stringArray(forKey: "advanced_tor_conf")
		}
		set {
			defaults?.set(newValue, forKey: "advanced_tor_conf")
		}
	}

	class var blockSources: [BlockerSourceType] {
		get {
			defaults?.stringArray(forKey: "block_sources")?.compactMap({ BlockerSourceType(rawValue: $0) }) ?? [.chromiumHsts]
		}
		set {
			defaults?.set(newValue.map({ $0.rawValue }), forKey: "block_sources")
		}
	}
}

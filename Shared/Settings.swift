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

	class override var defaults: UserDefaults? {
		UserDefaults(suiteName: Config.groupId)
	}

	class var onionOnly: Bool {
		get {
			defaults?.bool(forKey: "onion_only") ?? false
		}
		set {
			defaults?.set(newValue, forKey: "onion_only")
		}
	}

	class var entryNodes: String? {
		get {
			defaults?.string(forKey: "entry_nodes")
		}
		set {
			defaults?.set(newValue, forKey: "entry_nodes")
		}
	}

	class var exitNodes: String? {
		get {
			defaults?.string(forKey: "exit_nodes")
		}
		set {
			defaults?.set(newValue, forKey: "exit_nodes")
		}
	}

	class var excludeNodes: String? {
		get {
			defaults?.string(forKey: "exclude_nodes")
		}
		set {
			defaults?.set(newValue, forKey: "exclude_nodes")
		}
	}

	class var strictNodes: Bool {
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

	class var apiAccessTokens: [ApiToken] {
		get {
			(defaults?.dictionary(forKey: "api_access_tokens") as? [String: String])?
				.map { ApiToken(appId: $0, key: $1) } ?? []
		}
		set {
			var data = [String: String]()

			for token in newValue {
				data[token.appId] = token.key
			}

			defaults?.set(data, forKey: "api_access_tokens")
		}
	}
}

struct ApiToken {

	var appId: String

	var key: String
}

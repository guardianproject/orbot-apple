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

	class var bypassPort: UInt16? {
		get {
			if let port = defaults?.integer(forKey: "bypass_port"),
				port > 1023 && port != Config.webserverPort
			{
				return UInt16(port)
			}

			return nil
		}
		set {
			if newValue == nil {
				defaults?.removeObject(forKey: "bypass_port")
			}
			else {
				var port: Int

				repeat {
					port = Int.random(in: 1024...65535)
				} while port == Config.webserverPort

				defaults?.set(port, forKey: "bypass_port")
			}
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
			// Legacy support.
			if let dict = defaults?.dictionary(forKey: "api_access_tokens") as? [String: String] {
				return dict.map { ApiToken(appId: $0, key: $1, bypass: false) }
			}

			NSKeyedUnarchiver.setClass(ApiToken.self, forClassName: "ApiToken")

			if let data = defaults?.data(forKey: "api_access_tokens"),
			   let tokens = try? NSKeyedUnarchiver.unarchivedArrayOfObjects(ofClass: ApiToken.self, from: data)
			{
				return tokens
			}

			return []
		}
		set {
			NSKeyedArchiver.setClassName("ApiToken", for: ApiToken.self)

			defaults?.set(
				try? NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: true),
				forKey: "api_access_tokens")
		}
	}
}

class ApiToken: NSObject, NSSecureCoding {

	static var supportsSecureCoding = true


	var appId: String

	var key: String

	var bypass: Bool


	init(appId: String, key: String, bypass: Bool) {
		self.appId = appId
		self.key = key
		self.bypass = bypass
	}

	required init?(coder: NSCoder) {
		guard let appId = coder.decodeObject(forKey: "appId") as? String,
			  let key = coder.decodeObject(forKey: "key") as? String
		else {
			return nil
		}

		self.appId = appId
		self.key = key
		bypass = coder.decodeBool(forKey: "bypass")
	}


	func encode(with coder: NSCoder) {
		coder.encode(appId, forKey: "appId")
		coder.encode(key, forKey: "key")
		coder.encode(bypass, forKey: "bypass")
	}

	override var description: String {
		"[\(String(describing: type(of: self))) appId=\(appId), key=\(key), bypass=\(bypass)]"
	}
}

//
//  Settings.swift
//  Orbot
//
//  Created by Benjamin Erhart on 10.11.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import Foundation
import IPtProxy
import IPtProxyUI

class Settings: IPtProxyUI.Settings {

	class override var defaults: UserDefaults? {
		UserDefaults(suiteName: Config.groupId)
	}

	/**
	 Defaults to `true`!
	 */
	class var restartOnError: Bool {
		get {
			guard defaults?.object(forKey: "restart_on_error") != nil else {
				return true
			}

			return defaults?.bool(forKey: "restart_on_error") ?? true
		}
		set {
			defaults?.set(newValue, forKey: "restart_on_error")
		}
	}

	class var disableOnStop: Bool {
		get {
			defaults?.bool(forKey: "disable_on_stop") ?? false
		}
		set {
			defaults?.set(newValue, forKey: "disable_on_stop")
		}
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
				// There might still be a colision with the randomly selected
				// Tor and Tor Controller ports, but at least we will avoid this one.

				defaults?.set(port, forKey: "bypass_port")
			}
		}
	}

	class var entryNodes: String? {
		get {
			let value = defaults?.string(forKey: "entry_nodes")?.trimmingCharacters(in: .whitespacesAndNewlines)

			return value?.isEmpty ?? true ? nil : value
		}
		set {
			defaults?.set(newValue, forKey: "entry_nodes")
		}
	}

	class var exitNodes: String? {
		get {
			let value = defaults?.string(forKey: "exit_nodes")?.trimmingCharacters(in: .whitespacesAndNewlines)

			return value?.isEmpty ?? true ? nil : value
		}
		set {
			defaults?.set(newValue, forKey: "exit_nodes")
		}
	}

	class var excludeNodes: String? {
		get {
			let value = defaults?.string(forKey: "exclude_nodes")?.trimmingCharacters(in: .whitespacesAndNewlines)

			return value?.isEmpty ?? true ? nil : value
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

	class var disableGeoIp: Bool {
		get {
#if os(iOS)
			// On iOS, this defaults to true, to maximize the change of a successful start.
			guard defaults?.object(forKey: "disable_geo_ip") != nil else {
				return true
			}
#endif

			return defaults?.bool(forKey: "disable_geo_ip") ?? false
		}
		set {
			defaults?.set(newValue, forKey: "disable_geo_ip")
		}
	}

	class var advancedTorConf: [String]? {
		get {
			let value = defaults?.stringArray(forKey: "advanced_tor_conf")?
				.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
				.filter({ !$0.isEmpty })

			return value?.isEmpty ?? true ? nil : value
		}
		set {
			defaults?.set(newValue, forKey: "advanced_tor_conf")
		}
	}

	class var apiAccessTokens: [ApiToken] {
		get {
			// Legacy support.
			if let dict = defaults?.dictionary(forKey: "api_access_tokens") as? [String: String] {
				return dict.map { ApiToken(appId: $0, key: $1, appName: nil, bypass: false) }
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

	class var snowflakesHelpedTotal: Int {
		defaults?.integer(forKey: "snowflakes_helped") ?? 0
	}

	private class var snowflakesHelpedWeek: Int {
		get {
			defaults?.integer(forKey: "snowflakes_helped_week") ?? Calendar.current.component(.weekOfYear, from: Date())
		}
		set {
			defaults?.set(newValue, forKey: "snowflakes_helped_week")
		}
	}

	class var snowflakesHelpedWeekly: Int {
		if snowflakesHelpedWeek < Calendar.current.component(.weekOfYear, from: Date()) {
			snowflakesHelpedWeek = Calendar.current.component(.weekOfYear, from: Date())
			defaults?.set(0, forKey: "snowflakes_helped_weekly")
		}

		return defaults?.integer(forKey: "snowflakes_helped_weekly") ?? 0
	}

	class func addOneSnowflakeHelped() {
		defaults?.set(snowflakesHelpedTotal + 1, forKey: "snowflakes_helped")
		defaults?.set(snowflakesHelpedWeekly + 1, forKey: "snowflakes_helped_weekly")
	}

	class var smartConnect: Bool {
		get {
			guard defaults?.object(forKey: "smart_connect") != nil else {
				return true
			}

			return defaults?.bool(forKey: "smart_connect") ?? true
		}
		set {
			defaults?.set(newValue, forKey: "smart_connect")
		}
	}

	class var smartConnectTimeout: Double {
		get {
			guard defaults?.object(forKey: "smart_connect_timeout") != nil else {
				return 30
			}

			return defaults?.double(forKey: "smart_connect_timeout") ?? 30
		}
		set {
			defaults?.set(newValue, forKey: "smart_connect_timeout")
		}
	}

	class var alwaysClearCache: Bool {
		get {
#if os(iOS)
			// On iOS, this defaults to true, to maximize the change of a successful start.
			guard defaults?.object(forKey: "always_clear_cache") != nil else {
				return true
			}
#endif

			return defaults?.bool(forKey: "always_clear_cache") ?? false
		}
		set {
			defaults?.set(newValue, forKey: "always_clear_cache")
		}
	}
}

class ApiToken: NSObject, NSSecureCoding {

	static var supportsSecureCoding = true


	var appId: String

	var key: String

	var appName: String?

	var bypass: Bool

	var friendlyName: String {
		if let appName = appName, !appName.isEmpty {
			return "\(appName) (\(appId))"
		}

		return appId
	}


	init(appId: String, key: String, appName: String?, bypass: Bool) {
		self.appId = appId
		self.key = key
		self.appName = appName
		self.bypass = bypass
	}

	required init?(coder: NSCoder) {
		guard let appId = coder.decodeObject(of: NSString.self, forKey: "appId") as? String,
			  let key = coder.decodeObject(of: NSString.self, forKey: "key") as? String
		else {
			return nil
		}

		self.appId = appId
		self.key = key
		appName = coder.decodeObject(of: NSString.self, forKey: "appName") as? String
		bypass = coder.decodeBool(forKey: "bypass")
	}


	func encode(with coder: NSCoder) {
		coder.encode(appId, forKey: "appId")
		coder.encode(key, forKey: "key")
		coder.encode(appName, forKey: "appName")
		coder.encode(bypass, forKey: "bypass")
	}

	override var description: String {
		"[\(String(describing: type(of: self))) appId=\(appId), key=\(key), appName=\(appName ?? "(nil)"), bypass=\(bypass)]"
	}
}

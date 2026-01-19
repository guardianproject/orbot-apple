//
//  Settings.swift
//  Orbot
//
//  Created by Benjamin Erhart on 10.11.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import Foundation

public enum Transport: Int, CaseIterable, Comparable {

	public static let order: [Transport] = [.none, .obfs4, .snowflake, .snowflakeAmp, .meek, .custom, .onDemand]

	public static var customBridges: [String]?

	public static var proxy: URL?

	public static func asArguments(key: String, value: String) -> [String] {
		return ["--\(key)", value]
	}

	public static func asConf(key: String, value: String) -> [String: String] {
		return ["key": key, "value": "\"\(value)\""]
	}

	private static let snowflakeLogFileName = "snowflake.log"


	// MARK: Comparable

	public static func < (lhs: Transport, rhs: Transport) -> Bool {
		order.firstIndex(of: lhs) ?? lhs.rawValue < order.firstIndex(of: rhs) ?? rhs.rawValue
	}


	case none = 0
	case obfs4 = 1
	case snowflake = 2
	case custom = 3
	case snowflakeAmp = 4
	case onDemand = 5
	case meek = 6


	public var description: String {
		switch self {
		case .obfs4:
			return "Obfs4 bridges"

		case .snowflake:
			return "Snowflake bridges"

		case .snowflakeAmp:
			return "Snowflake bridges (AMP rendezvous)"

		case .custom:
			return "custom bridges"

		case .onDemand:
			return "On-demand bridges"

		case .meek:
			return "Meek bridge"

		default:
			return ""
		}
	}

	/**
	 Returns the location of the log file of the transport, if it can provide any.

	 ATTENTION: You will need to have set `Settings.stateLocation` to a writable directory before calling this!
	 Otherwise this will return nonsense.
	 */
	public var logFile: URL? {
		switch self {
		case .obfs4, .custom, .onDemand, .meek:
			return Settings.stateLocation.appendingPathComponent("obfs4proxy.log")

		case .snowflake, .snowflakeAmp:
			return Settings.stateLocation.appendingPathComponent(Self.snowflakeLogFileName)

		default:
			return nil
		}
	}

	public var error: Error? {
		nil
	}

	/**
	 Start the transport, if it is startable.
	 */
	public func start() throws {
	}

	public func stop() {
	}

	public func torConf<T>(_ cv: (String, String) -> T, onDemandBridges: [String]? = nil, customBridges: [String]? = nil) -> [T] {
		var conf = [T]()

		if self == .none {
			if let proxy = Settings.proxy,
			   let hostPort = proxy.hostPort
			{
				switch proxy.scheme {
				case "https":
					conf.append(cv("HTTPSProxy", hostPort))

					if let username = proxy.user, !username.isEmpty {
						conf.append(cv("HTTPSProxyAuthenticator", "\(username):\(proxy.password ?? "")"))
					}

				case "socks4":
					conf.append(cv("Socks4Proxy", hostPort))

				case "socks5":
					conf.append(cv("Socks5Proxy", hostPort))

					if let username = proxy.user, !username.isEmpty {
						conf.append(cv("Socks5ProxyUsername", username))

						var password = proxy.password ?? " "
						if password.isEmpty {
							password = " "
						}

						conf.append(cv("Socks5ProxyPassword", password))
					}

				default:
					break
				}
			}
		}

		return conf
	}
}

extension URL {

	var hostPort: String? {
		var value: String?

		if let host = host, !host.isEmpty {
			value = host

			if let port = port {
				value?.append(":\(port)")
			}
		}

		return value
	}
}

class Settings {

	class var defaults: UserDefaults? {
		UserDefaults(suiteName: Config.groupId)
	}

	// MARK: IPtProxyUI mocks

	open class var transport: Transport {
		get {
			Transport(rawValue: defaults?.integer(forKey: "transport") ?? 0) ?? .none
		}
		set {
			defaults?.set(newValue.rawValue, forKey: "transport")
		}
	}

	open class var customBridges: [String]? {
		get {
			nil
		}
		set {
		}
	}

	open class var onDemandBridges: [String]? {
		get {
			nil
		}
		set {
		}
	}

	open class var stateLocation: URL {
		get {
			FileManager.default.ptDir!
		}
		set {
		}
	}

	class var proxy: URL? {
		get {
			guard let proxy = defaults?.string(forKey: "proxy") else {
				return nil
			}

			return URL(string: proxy)
		}
		set {
			defaults?.set(newValue?.absoluteString, forKey: "proxy")
		}
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

	class var isolateDestAddr: Bool {
		get {
			defaults?.bool(forKey: "isolate_dest_addr") ?? false
		}
		set {
			defaults?.set(newValue, forKey: "isolate_dest_addr")
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

	class var snowflakesHelped: Int {
		get {
			defaults?.integer(forKey: "snowflakes_helped") ?? 0
		}
		set {
			defaults?.set(newValue, forKey: "snowflakes_helped")
		}
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

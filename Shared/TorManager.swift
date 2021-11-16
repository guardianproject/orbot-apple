//
//  TorManager.swift
//  Orbot
//
//  Created by Benjamin Erhart on 17.05.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import NetworkExtension
import Tor

#if os(iOS)
import IPtProxy
#endif


class TorManager {

	private enum Errors: Error {
		case cookieUnreadable
	}

	static let shared = TorManager()

	static let localhost = "127.0.0.1"

	static let torProxyPort: UInt16 = 9050
	static let dnsPort: UInt16 = 5400

	private static let torControlPort: UInt16 = 39060


	private var torThread: TorThread?

	private var torController: TorController?

	private var torConf: TorConfiguration?

	private var torRunning: Bool {
		guard torThread?.isExecuting ?? false else {
			return false
		}

		if let lock = torConf?.dataDirectory?.appendingPathComponent("lock") {
			return FileManager.default.fileExists(atPath: lock.path)
		}

		return false
	}

	private var cookie: Data? {
		if let cookieUrl = torConf?.dataDirectory?.appendingPathComponent("control_auth_cookie") {
			return try? Data(contentsOf: cookieUrl)
		}

		return nil
	}

	private lazy var controllerQueue = DispatchQueue.global(qos: .userInitiated)


	private init() {
	}

	func start(_ bridge: Bridge,
			   _ progressCallback: @escaping (Int) -> Void,
			   _ completion: @escaping (Error?) -> Void)
	{
		if !torRunning {
			torConf = getTorConf(bridge)

			torThread = TorThread(configuration: torConf)

			torThread?.start()
		}
		else {
			torController?.resetConf(forKey: "UseBridges")
			{ [weak self] success, error in
				if !success {
					return
				}

				self?.torController?.resetConf(forKey: "ClientTransportPlugin")
				{ [weak self] success, error in
					if !success {
						return
					}

					self?.torController?.resetConf(forKey: "Bridge")
					{ [weak self] success, error in
						if !success {
							return
						}

						self?.torController?.setConfs(
							self?.getBridgeConfig(bridge, { ["key": $0, "value": "\"\($1)\""] }) ?? [])
					}
				}
			}
		}

		controllerQueue.asyncAfter(deadline: .now() + 0.65) {
			if self.torController == nil {
				self.torController = TorController(
					socketHost: Self.localhost,
					port: Self.torControlPort)
			}

			if !(self.torController?.isConnected ?? false) {
				do {
					try self.torController?.connect()
				}
				catch let error {
					self.log("#startTunnel error=\(error)")

					return completion(error)
				}
			}

			guard let cookie = self.cookie else {
				self.log("#startTunnel cookie unreadable")

				return completion(Errors.cookieUnreadable)
			}

			self.torController?.authenticate(with: cookie) { success, error in
				if let error = error {
					self.log("#startTunnel error=\(error)")

					return completion(error)
				}

				var progressObs: Any?
				progressObs = self.torController?.addObserver(forStatusEvents: {
					(type, severity, action, arguments) -> Bool in

					if type == "STATUS_CLIENT" && action == "BOOTSTRAP" {
						let progress = Int(arguments!["PROGRESS"]!)!
						self.log("#startTunnel progress=\(progress)")

						progressCallback(progress)

						if progress >= 100 {
							self.torController?.removeObserver(progressObs)
						}

						return true
					}

					return false
				})

				var observer: Any?
				observer = self.torController?.addObserver(forCircuitEstablished: { established in
					guard established else {
						return
					}

					self.torController?.removeObserver(observer)

					completion(nil)
				})
			}
		}
	}

	func stop() {
		torController?.disconnect()
		torController = nil

		torThread?.cancel()
		torThread = nil

		torConf = nil
	}

	func getCircuits(_ completion: @escaping ([TorCircuit]) -> Void) {
		torController?.getCircuits(completion)
	}

	func close(_ circuits: [TorCircuit], _ completion: ((Bool) -> Void)?) {
		torController?.close(circuits, completion: completion)
	}


	// MARK: Private Methods

	private func log(_ message: String) {
		Logger.log(message, to: Logger.vpnLogfile)
	}

	private func getTorConf(_ bridge: Bridge) -> TorConfiguration {
		let conf = TorConfiguration()

		conf.options = [
			// DNS
			"DNSPort": "\(Self.localhost):\(Self.dnsPort)",
			"AutomapHostsOnResolve": "1",
			// By default, localhost resp. link-local addresses will be returned by Tor.
			// That seems to not get accepted by iOS. Use private network addresses instead.
			"VirtualAddrNetworkIPv4": "10.192.0.0/10",
			"VirtualAddrNetworkIPv6": "[FC00::]/7",

			// Log
			"LogMessageDomains": "1",
			"SafeLogging": "1",

			// Ports
			"SocksPort": "\(Self.localhost):\(Self.torProxyPort)",
			"ControlPort": "\(Self.localhost):\(Self.torControlPort)",

			// GeoIP files for circuit node country display.
			"GeoIPFile": Bundle.main.path(forResource: "geoip", ofType: nil) ?? "",
			"GeoIPv6File": Bundle.main.path(forResource: "geoip6", ofType: nil) ?? "",

			// v3 Onion Service Authentication
			"ClientOnionAuthDir": FileManager.default.torAuthDir?.path ?? "",

			// Miscelaneous
			"ClientOnly": "1",
			"AvoidDiskWrites": "1",
			"MaxMemInQueues": "5MB"]


		conf.cookieAuthentication = true
		conf.dataDirectory = FileManager.default.torDir

		conf.arguments += [
			"--allow-missing-torrc",
			"--ignore-missing-torrc",
		]

		conf.arguments += getBridgeConfig(bridge, { ["--\($0)", $1] }).joined()

		if Logger.ENABLE_LOGGING,
		   let logfile = FileManager.default.torLogFile
		{
			try? "".write(to: logfile, atomically: true, encoding: .utf8)

			conf.options["Log"] = "notice file \(logfile.path)"
		}

		return conf
	}

	private func getBridgeConfig<T>(_ bridge: Bridge, _ cv: (String, String) -> T) -> [T] {
		var arguments = [T]()

#if os(iOS)
		switch bridge {
		case .obfs4, .custom:
			arguments.append(cv("ClientTransportPlugin", "obfs4 socks5 \(Self.localhost):\(IPtProxyObfs4Port())"))

			let bridges = bridge == .custom ? FileManager.default.customObfs4Bridges : FileManager.default.builtInObfs4Bridges
			arguments += bridges?.map({ cv("Bridge", $0) }) ?? []

			arguments.append(cv("UseBridges", "1"))

		case .snowflake:
			arguments.append(cv("ClientTransportPlugin", "snowflake socks5 \(Self.localhost):\(IPtProxySnowflakePort())"))
			arguments.append(cv("Bridge", "snowflake 192.0.2.3:1 2B280B23E1107BB62ABFC40DDCC8824814F80A72"))
			arguments.append(cv("UseBridges", "1"))

		default:
			arguments.append(cv("UseBridges", "0"))
		}
#endif

		return arguments
	}
}

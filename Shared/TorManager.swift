//
//  TorManager.swift
//  Orbot
//
//  Created by Benjamin Erhart on 17.05.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import NetworkExtension
import Tor
import IPtProxyUI


class TorManager {

	private enum Errors: Error {
		case cookieUnreadable
		case noSocksAddr
		case noDnsAddr
	}

	static let shared = TorManager()

	static let localhost = "127.0.0.1"


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

	private lazy var controllerQueue = DispatchQueue.global(qos: .userInitiated)

	private var transport = Transport.none

	private var ipStatus = IpSupport.Status.unknown


	private init() {
		IpSupport.shared.start({ [weak self] status in
			self?.ipStatus = status

			if self?.torRunning ?? false && self?.torController?.isConnected ?? false {
				self?.torController?.setConfs(self?.ipConf(Transport.asConf) ?? []) { success, error in
					if let error = error {
						print("[\(String(describing: type(of: self)))] error: \(error)")
					}

					self?.torController?.resetConnection()
				}
			}
		})
	}

	func start(_ transport: Transport,
			   _ progressCallback: @escaping (Int) -> Void,
			   _ completion: @escaping (Error?, _ socksAddr: String?, _ dnsAddr: String?) -> Void)
	{
		self.transport = transport

		if !torRunning {
			torConf = getTorConf()

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
							self?.transportConf(Transport.asConf) ?? [])
					}
				}
			}
		}

		controllerQueue.asyncAfter(deadline: .now() + 0.65) {
			if self.torController == nil, let url = self.torConf?.controlPortFile {
				self.torController = TorController(controlPortFile: url)
			}

			if !(self.torController?.isConnected ?? false) {
				do {
					try self.torController?.connect()
				}
				catch let error {
					self.log("#startTunnel error=\(error)")

					return completion(error, nil, nil)
				}
			}

			guard let cookie = self.torConf?.cookie else {
				self.log("#startTunnel cookie unreadable")

				return completion(Errors.cookieUnreadable, nil, nil)
			}

			self.torController?.authenticate(with: cookie) { success, error in
				if let error = error {
					self.log("#startTunnel error=\(error)")

					return completion(error, nil, nil)
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

					self.torController?.getInfoForKeys(["net/listeners/socks", "net/listeners/dns"]) { response in
						guard let socksAddr = response.first, !socksAddr.isEmpty else {
							return completion(Errors.noSocksAddr, nil, nil)
						}

						guard let dnsAddr = response.last, !dnsAddr.isEmpty else {
							return completion(Errors.noDnsAddr, nil, nil)
						}

						completion(nil, socksAddr, dnsAddr)
					}
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

	private func getTorConf() -> TorConfiguration {
		let conf = TorConfiguration()

		conf.options = [
			// DNS
			"DNSPort": "auto",
			"AutomapHostsOnResolve": "1",
			// By default, localhost resp. link-local addresses will be returned by Tor.
			// That seems to not get accepted by iOS. Use private network addresses instead.
			"VirtualAddrNetworkIPv4": "10.192.0.0/10",
			"VirtualAddrNetworkIPv6": "[FC00::]/7",

			// Log
			"LogMessageDomains": "1",
			"SafeLogging": "1",

			// Ports
			"SocksPort": "auto",

			// GeoIP files for circuit node country display.
			"GeoIPFile": Bundle.main.path(forResource: "geoip", ofType: nil) ?? "",
			"GeoIPv6File": Bundle.main.path(forResource: "geoip6", ofType: nil) ?? "",

			// Miscelaneous
			"ClientOnly": "1",
			"AvoidDiskWrites": "1",
			"MaxMemInQueues": "5MB"]


		conf.ignoreMissingTorrc = true
		conf.cookieAuthentication = true
		conf.autoControlPort = true
		conf.dataDirectory = FileManager.default.torDir
		conf.clientAuthDirectory = FileManager.default.torAuthDir

		conf.arguments += transportConf(Transport.asArguments).joined()

		conf.arguments += ipConf(Transport.asArguments).joined()

		if Logger.ENABLE_LOGGING,
		   let logfile = FileManager.default.torLogFile
		{
			try? "".write(to: logfile, atomically: true, encoding: .utf8)

			conf.options["Log"] = "notice file \(logfile.path)"
		}

		return conf
	}

	private func transportConf<T>(_ cv: (String, String) -> T) -> [T] {

		var arguments = transport.torConf(cv)

		if transport == .custom, let bridgeLines = FileManager.default.customObfs4Bridges {
			arguments += bridgeLines.map({ cv("Bridge", $0) })
		}

		if transport == .none {
			arguments.append(cv("UseBridges", "0"))
		}
		else {
			arguments.append(cv("UseBridges", "1"))
		}

		return arguments
	}

	private func ipConf<T>(_ cv: (String, String) -> T) -> [T] {
		var arguments = [T]()

		if ipStatus == .ipV6Only {
			arguments.append(cv("ClientPreferIPv6ORPort", "1"))

			if transport == .none {
				// Switch off IPv4, if we're on a IPv6-only network.
				arguments.append(cv("ClientUseIPv4", "0"))
			}
			else {
				// ...but not, when we're using a transport. The bridge
				// configuration lines are what is important, then.
				arguments.append(cv("ClientUseIPv4", "1"))
			}
		}
		else {
			arguments.append(cv("ClientPreferIPv6ORPort", "auto"))
			arguments.append(cv("ClientUseIPv4", "1"))
		}

		arguments.append(cv("ClientUseIPv6", "1"))

		return arguments
	}
}

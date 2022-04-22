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

	enum Status: String {
		case stopped = "stopped"
		case starting = "starting"
		case started = "started"
	}

	private enum Errors: Error {
		case cookieUnreadable
		case noSocksAddr
		case noDnsAddr
	}

	static let shared = TorManager()

	static let localhost = "127.0.0.1"

	var status = Status.stopped

	private var torThread: TorThread?

	private var torController: TorController?

	private var torConf: TorConfiguration?

	private var torRunning: Bool {
		(torThread?.isExecuting ?? false) && (torConf?.isLocked ?? false)
	}

	private lazy var controllerQueue = DispatchQueue.global(qos: .userInitiated)

	private var transport = Transport.none

	private var ipStatus = IpSupport.Status.unavailable


	private init() {
		IpSupport.shared.start({ [weak self] status in
			self?.ipStatus = status

			if (self?.torRunning ?? false) && (self?.torController?.isConnected ?? false) {
				self?.torController?.setConfs(status.torConf(self?.transport ?? .none, Transport.asConf))
				{ success, error in
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
		status = .starting

		self.transport = transport

		if !torRunning {
			torConf = getTorConf()

//			if let debug = torConf?.compile().joined(separator: ", ") {
//				Logger.log(debug, to: FileManager.default.torLogFile)
//			}

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

					self.status = .stopped

					return completion(error, nil, nil)
				}
			}

			guard let cookie = self.torConf?.cookie else {
				self.log("#startTunnel cookie unreadable")

				self.status = .stopped

				return completion(Errors.cookieUnreadable, nil, nil)
			}

			self.torController?.authenticate(with: cookie) { success, error in
				if let error = error {
					self.log("#startTunnel error=\(error)")

					self.status = .stopped

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
							self.status = .stopped

							return completion(Errors.noSocksAddr, nil, nil)
						}

						guard let dnsAddr = response.last, !dnsAddr.isEmpty else {
							self.status = .stopped

							return completion(Errors.noDnsAddr, socksAddr, nil)
						}

						self.status = .started

						completion(nil, socksAddr, dnsAddr)
					}
				})
			}
		}
	}

	func stop() {
		status = .stopped

		torController?.disconnect()
		torController = nil

		torThread?.cancel()
		torThread = nil

		torConf = nil
	}

	func getCircuits(_ completion: @escaping ([TorCircuit]) -> Void) {
		if let torController = torController {
			torController.getCircuits(completion)
		}
		else {
			completion([])
		}
	}

	func close(_ circuits: [TorCircuit], _ completion: ((Bool) -> Void)?) {
		if let torController = torController {
			torController.close(circuits, completion: completion)
		}
		else {
			completion?(false)
		}
	}


	// MARK: Private Methods

	private func log(_ message: String) {
		Logger.log(message, to: Logger.vpnLogFile)
	}

	private func getTorConf() -> TorConfiguration {
		let conf = TorConfiguration()

		conf.ignoreMissingTorrc = true
		conf.cookieAuthentication = true
		conf.autoControlPort = true
		conf.clientOnly = true
		conf.avoidDiskWrites = true
		conf.dataDirectory = FileManager.default.torDir
		conf.clientAuthDirectory = FileManager.default.torAuthDir

		// GeoIP files for circuit node country display.
		conf.geoipFile = Bundle.geoIp?.geoipFile
		conf.geoip6File = Bundle.geoIp?.geoip6File

		// Add user-defined configuration.
		conf.arguments += Settings.advancedTorConf ?? []

		conf.arguments += transportConf(Transport.asArguments).joined()

		conf.arguments += ipStatus.torConf(transport, Transport.asArguments).joined()

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

			// SOCKS5
			"SocksPort": "auto",

			// Miscelaneous
			"MaxMemInQueues": "5MB"]

		// Node in-/exclusions
		if let entryNodes = Settings.entryNodes {
			conf.options["EntryNodes"] = entryNodes
		}

		if let exitNodes = Settings.exitNodes {
			conf.options["ExitNodes"] = exitNodes
		}

		if let excludeNodes = Settings.excludeNodes {
			conf.options["ExcludeNodes"] = excludeNodes
			conf.options["StrictNodes"] = Settings.strictNodes ? "1" : "0"
		}

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

		if transport == .custom, let bridgeLines = Settings.customBridges {
			arguments += bridgeLines.map({ cv("Bridge", $0) })
		}

		arguments.append(cv("UseBridges", transport == .none ? "0" : "1"))

		return arguments
	}
}

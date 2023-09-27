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

	enum Status: String, Codable {
		case stopped = "stopped"
		case starting = "starting"
		case started = "started"
	}

	enum Errors: Error, LocalizedError {
		case cookieUnreadable
		case noSocksAddr
		case noDnsAddr
		case smartConnectFailed

		var errorDescription: String? {
			switch self {

			case .cookieUnreadable:
				return "Tor cookie unreadable"

			case .noSocksAddr:
				return "No SOCKS port"

			case .noDnsAddr:
				return "No DNS port"

			case .smartConnectFailed:
				return "Smart Connect failed"
			}
		}
	}

	static let shared = TorManager()

	static let localhost = "127.0.0.1"

	private static let artiSocksPort: UInt = 9050
	private static let artiDnsPort: UInt = 9051

	var status = Status.stopped

	private var torThread: Thread?

	private var torController: TorController?

	private var torConf: TorConfiguration?

	private var _torRunning = false
	private var torRunning: Bool {
		 ((torThread?.isExecuting ?? false) && (torConf?.isLocked ?? false)) || _torRunning
	}

	private lazy var controllerQueue = DispatchQueue.global(qos: .userInitiated)

	private var transport = Transport.none

	private var ipStatus = IpSupport.Status.unavailable

	private var progressObs: Any?
	private var establishedObs: Any?


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
			   fd: Int32? = nil,
			   _ progressCallback: @escaping (_ progress: Int?) -> Void,
			   _ completion: @escaping (Error?, _ socksAddr: String?, _ dnsAddr: String?) -> Void)
	{
		status = .starting

		self.transport = transport

#if USE_ARTI
		if !torRunning {
			let fm = FileManager.default

			let conf = TorConfiguration()
			conf.socksPort = Self.artiSocksPort
			conf.dnsPort = Self.artiDnsPort
			conf.dataDirectory = fm.artiStateDir
			conf.cacheDirectory = fm.artiCacheDir
			conf.logfile = fm.torLogFile?.truncate()

			TorArti.start(with: conf) { [weak self] in
				self?.status = .started
				self?._torRunning = true

				completion(nil, "\(Self.localhost):\(Self.artiSocksPort)", "\(Self.localhost):\(Self.artiDnsPort)")
			}
		}
		else {
			status = .started

			completion(nil, "\(Self.localhost):\(Self.artiSocksPort)", "\(Self.localhost):\(Self.artiDnsPort)")
		}

		return

#elseif USE_ONIONMASQ
		if !torRunning {
			let fm = FileManager.default

			fm.torLogFile?.truncate()

			Logger.log("groupDir=\(fm.groupDir?.path ?? "(nil)")", to: fm.torLogFile)

			let tracefile = fm.groupDir?.appendingPathComponent("trace.pcap")
			Logger.log("tracefile=\(tracefile?.path ?? "(nil)")", to: fm.torLogFile)

			Onionmasq.start(
				withFd: fd!, stateDir: fm.groupDir, cacheDir: fm.groupDir, pcapFile: tracefile,
				onEvent: { [weak self] event in
					if let event = event as? String {
						return Logger.log(event, to: FileManager.default.torLogFile)
					}

					if let event = event as? Dictionary<String, Any> {
						switch event["type"] as? String {
						case "Bootstrap":
							let progress = event["bootstrap_percent"] as? Int

							self?.log("#startTunnel progress=\(progress?.description ?? "(nil)")")

							progressCallback(progress)

							if event["is_ready_for_traffic"] as? Bool ?? false {
								self?.status = .started
								self?._torRunning = true

								completion(nil, nil, nil)
							}

						default:
							break
						}
					}

					Logger.log(String(describing: event), to: FileManager.default.torLogFile)
				}, onLog: { log in
					Logger.log(log, to: FileManager.default.torLogFile)
				})
		}
		else {
			status = .started

			completion(nil, nil, nil)
		}
#else
		if !torRunning {
			torConf = getTorConf()

//			if let debug = torConf?.compile().joined(separator: ", ") {
//				Logger.log(debug, to: FileManager.default.torLogFile)
//			}

			torThread = TorThread(configuration: torConf)

			torThread?.start()
		}
		else {
			updateConfig(transport)
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

				self.progressObs = self.torController?.addObserver(forStatusEvents: {
					[weak self] (type, severity, action, arguments) -> Bool in

					if type == "STATUS_CLIENT" && action == "BOOTSTRAP" {
						let progress: Int?

						if let p = arguments?["PROGRESS"] {
							progress = Int(p)
						}
						else {
							progress = nil
						}

						self?.log("#startTunnel progress=\(progress?.description ?? "(nil)")")

						progressCallback(progress)

						if progress ?? 0 >= 100 {
							self?.torController?.removeObserver(self?.progressObs)
						}

						return true
					}

					return false
				})

				self.establishedObs = self.torController?.addObserver(forCircuitEstablished: { [weak self] established in
					guard established else {
						return
					}

					self?.torController?.removeObserver(self?.establishedObs)
					self?.torController?.removeObserver(self?.progressObs)

					self?.torController?.getInfoForKeys(["net/listeners/socks", "net/listeners/dns"]) { response in
						guard let socksAddr = response.first, !socksAddr.isEmpty else {
							self?.status = .stopped

							return completion(Errors.noSocksAddr, nil, nil)
						}

						guard let dnsAddr = response.last, !dnsAddr.isEmpty else {
							self?.status = .stopped

							return completion(Errors.noDnsAddr, socksAddr, nil)
						}

						self?.status = .started

						completion(nil, socksAddr, dnsAddr)
					}
				})
			}
		}
#endif
	}

	func updateConfig(_ transport: Transport) {
		self.transport = transport

		let group = DispatchGroup()

		let resetKeys = ["UseBridges", "ClientTransportPlugin", "Bridge",
						 "EntryNodes", "ExitNodes", "ExcludeNodes", "StrictNodes"]

		for key in resetKeys {
			group.enter()

			torController?.resetConf(forKey: key) { _, error in
				if let error = error {
					debugPrint(error)
				}

				group.leave()
			}

			group.wait()
		}

		torController?.setConfs(nodeConf(Transport.asConf) + transportConf(Transport.asConf))
	}

	func stop() {
		status = .stopped

		torController?.removeObserver(self.establishedObs)
		torController?.removeObserver(self.progressObs)

		torController?.disconnect()
		torController = nil

		torThread?.cancel()
		torThread = nil

		torConf = nil

#if USE_ONIONMASQ
		Onionmasq.stop()
#endif
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

	func close(_ ids: [String], _ completion: ((Bool) -> Void)?) {
		if let torController = torController {
			torController.closeCircuits(byIds: ids, completion: completion)
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

		conf.arguments += nodeConf(Transport.asArguments).joined()

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
			"SocksPort": "auto"]

#if os(iOS)
		// Reduce Tor's memory footprint.
		// Allow users to play with that number themselves.
		if !conf.arguments.contains(where: { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == "--maxmeminqueues" }) {
			conf.options["MaxMemInQueues"] = "5MB"
		}
#endif

		if Logger.ENABLE_LOGGING,
		   let logfile = FileManager.default.torLogFile?.truncate()
		{
			conf.options["Log"] = "notice file \(logfile.path)"
		}

		return conf
	}

	private func nodeConf<T>(_ cv: (String, String) ->T) -> [T] {
		var conf = [T]()

		// Node in-/exclusions
		// BUGFIX: Tor doesn't allow EntryNodes and UseBridges at once!
		if transport == .none, let entryNodes = Settings.entryNodes {
			conf.append(cv("EntryNodes", entryNodes))
		}

		if let exitNodes = Settings.exitNodes {
			conf.append(cv("ExitNodes", exitNodes))
		}

		if let excludeNodes = Settings.excludeNodes {
			conf.append(cv("ExcludeNodes", excludeNodes))
			conf.append(cv("StrictNodes", Settings.strictNodes ? "1" : "0"))
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

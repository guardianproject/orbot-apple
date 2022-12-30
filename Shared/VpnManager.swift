//
//  VpnManager.swift
//  Orbot
//
//  Created by Benjamin Erhart on 20.05.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import NetworkExtension
import Tor
import IPtProxyUI

extension Notification.Name {
	static let vpnStatusChanged = Notification.Name("vpn-status-changed")
	static let vpnProgress = Notification.Name("vpn-progress")
}

class VpnManager: BridgesConfDelegate {

	typealias Completed = (_ success: Bool) -> Void

	enum Status: CustomStringConvertible {

		case notInstalled
		case disabled
		case invalid
		case disconnected
		case evaluating
		case connecting
		case connected
		case reasserting
		case disconnecting
		case unknown


		var description: String {
			switch self {
			case .notInstalled:
				return NSLocalizedString("Not Installed", comment: "")

			case .disabled:
				return NSLocalizedString("Disabled", comment: "")

			case .invalid:
				return NSLocalizedString("Invalid", comment: "")

			case .disconnected:
				return NSLocalizedString("Ready to Connect", comment: "")

			case .evaluating:
				return NSLocalizedString("Evaluating", comment: "")

			case .connecting:
				return NSLocalizedString("Connecting", comment: "")

			case .connected:
				return NSLocalizedString("Connected", comment: "")

			case .reasserting:
				return NSLocalizedString("Reasserting", comment: "")

			case .disconnecting:
				return NSLocalizedString("Disconnecting", comment: "")

			case .unknown:
				return NSLocalizedString("Unknown", comment: "")
			}
		}
	}

	enum Errors: LocalizedError {
		public var errorDescription: String? {
			switch self {
			case .noConfiguration:
				return NSLocalizedString("No VPN configuration set.", comment: "")

			case .couldNotConnect:
				return NSLocalizedString("Could not connect.", comment: "")
			}
		}

		case noConfiguration
		case couldNotConnect
	}


	static let shared = VpnManager()

	private var manager: NETunnelProviderManager?

	private var session: NETunnelProviderSession? {
		return manager?.connection as? NETunnelProviderSession
	}

	private var poll = false

	private var evaluating = false

	var status: Status {
#if DEBUG
		if Config.screenshotMode {
			return .connected
		}
#endif

		guard let manager = manager else {
			return .notInstalled
		}

		guard manager.isEnabled else {
			return .disabled
		}

		guard !evaluating else {
			return .evaluating
		}

		switch session?.status ?? .invalid {
		case .invalid:
			return .invalid

		case .disconnected:
			return .disconnected

		case .connecting:
			return .connecting

		case .connected:
			return .connected

		case .reasserting:
			return .reasserting

		case .disconnecting:
			return .disconnecting

		@unknown default:
			return .unknown
		}
	}

	private var _error: Error?
	private(set) var error: Error? {
		get {
#if DEBUG
			if Config.screenshotMode {
				return nil
			}
#endif

			return _error
		}
		set {
			_error = newValue
		}
	}

	var isConnected: Bool {
		switch status {
		case  .evaluating, .connecting, .connected, .reasserting:
			return true

		default:
			return false
		}
	}


	init() {
		NSKeyedUnarchiver.setClass(ProgressMessage.self, forClassName:
									"TorVPN.\(String(describing: ProgressMessage.self))")

		NSKeyedUnarchiver.setClass(ProgressMessage.self, forClassName:
									"TorVPN_Mac.\(String(describing: ProgressMessage.self))")

		NSKeyedUnarchiver.setClass(ConfigChangedMessage.self, forClassName:
									"TorVPN.\(String(describing: ConfigChangedMessage.self))")

		NSKeyedUnarchiver.setClass(ConfigChangedMessage.self, forClassName:
									"TorVPN_Mac.\(String(describing: ConfigChangedMessage.self))")

		NotificationCenter.default.addObserver(
			self, selector: #selector(statusDidChange),
			name: .NEVPNStatusDidChange, object: nil)

		reload()
	}

	func reload(_ completed: Completed? = nil) {
		NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
			self?.error = error
			self?.manager = managers?.first(where: { $0.isEnabled }) ?? managers?.first

			self?.postChange()

			completed?(self?.manager != nil)
		}
	}

	func install(_ completed: Completed? = nil) {
		let conf = NETunnelProviderProtocol()
		conf.providerBundleIdentifier = Config.extBundleId
		conf.serverAddress = "Tor" // Needs to be set to something, otherwise error.

		let manager = NETunnelProviderManager()
		manager.protocolConfiguration = conf
		manager.localizedDescription = Bundle.main.displayName

		// Add a "always connect" rule to avoid leakage after the network
		// extension got killed.
		manager.onDemandRules = [NEOnDemandRuleConnect()]

		manager.isEnabled = true

		save(manager, completed)
	}

	func enable(_ completed: Completed? = nil) {
		guard let manager = manager else {
			completed?(false)

			return
		}

		manager.isEnabled = true

		save(manager, completed)
	}

	func disable(_ completed: Completed? = nil) {
		guard let manager = manager else {
			completed?(false)

			return
		}

		manager.isEnabled = false

		save(manager, completed)
	}

	func configChanged() {
		if isConnected {
			sendMessage(ConfigChangedMessage()) { (success: Bool?, error) in
				print("[\(String(describing: type(of: self)))] success=\(success ?? false), error=\(String(describing: error))")

				self.error = error

				self.postChange()
			}
		}
	}

	func connect(autoConfDone: Bool = false) {
		if Settings.smartConnect && !autoConfDone {
			// Has to be switched off, first, otherwise AutoConf request would trigger a connection
			// which we're trying to configure first!
			if let manager = manager, manager.isOnDemandEnabled {
				manager.isOnDemandEnabled = false

				save(manager) { [weak self] success in
					self?.connect()
				}
			}
			else {
				evaluating = true
				postChange()

				AutoConf(self).do { [weak self] error in
					if let error = error {
						self?.error = error

						self?.postChange()

						// If the API is broken, we continue with our own smart-connect logic.
						Settings.transport = .none
					}

					// Continue in any case, don't let us stop because of a broken config API.
					self?.connect(autoConfDone: true)
				}
			}

			return
		}

		let completed: Completed = { [weak self] success in
			guard success,
				  let session = self?.session
			else {
				self?.error = Errors.noConfiguration
				self?.evaluating = false

				self?.postChange()

				return
			}

			DispatchQueue.main.async {
				guard let self = self else {
					return
				}

				self.evaluating = false

				do {
					try session.startVPNTunnel()
				}
				catch let error {
					self.error = error

					self.postChange()

					return
				}

				self.commTunnel()
			}
		}

		// If user wants to automatically restart on error, but
		// start-on-demand is not set, set it now and store the config.
		if Settings.restartOnError, let manager = manager, !manager.isOnDemandEnabled {
			manager.isOnDemandEnabled = true

			save(manager, completed)
		}
		else {
			completed(true)
		}
	}

	func disconnect(explicit: Bool) {
		let completed: Completed = { [weak self] _ in
			self?.session?.stopTunnel()
		}

		// If user pressed stop explicitly and  start-on-demand is set, unset it now,
		// otherwise it would constantly restart.
		if explicit, let manager = manager, manager.isOnDemandEnabled {
			manager.isOnDemandEnabled = false

			save(manager, completed)
		}
		else {
			completed(true)
		}
	}

	/**
	 If Network Extension is currently running

	 - then, if  restart-on-error was just set and start-on-demand is currently not set, set it.
	 - else if restart-on-error was just unset and start-on-demand is currently set, unset it.
	 */
	func updateRestartOnError() {
		if isConnected,
			let manager = manager, manager.isOnDemandEnabled != Settings.restartOnError
		{
			manager.isOnDemandEnabled = Settings.restartOnError

			save(manager)
		}
	}

	func getCircuits(_ callback: @escaping ((_ circuits: [TorCircuit], _ error: Error?) -> Void)) {
		sendMessage(GetCircuitsMessage()) { (circuits: [TorCircuit]?, error) in
			callback(circuits ?? [], error)
		}
	}

	func closeCircuits(_ circuits: [TorCircuit], _ callback: @escaping ((_ success: Bool, _ error: Error?) -> Void)) {
		sendMessage(CloseCircuitsMessage(circuits)) { (success: Bool?, error) in
			callback(success ?? false, error)
		}
	}


	// MARK: BridgesConfDelegate

	var transport: Transport {
		get {
			Settings.transport
		}
		set {
			Settings.transport = newValue
		}
	}

	var customBridges: [String]? {
		get {
			Settings.customBridges
		}
		set {
			Settings.customBridges = newValue
		}
	}

	func save() {
		// Ignored.
	}


	// MARK: Private Methods

	private func save(_ manager: NETunnelProviderManager, _ completed: Completed? = nil) {
		manager.saveToPreferences { [weak self] error in
			self?.error = error

			// Always re-load the manager from preferences, otherwise changes
			// won't be applied and the manager cannot be used as expected.
			self?.reload(completed)
		}
	}

	@objc
	private func statusDidChange(_ notification: Notification) {
		switch session?.status ?? .invalid {
		case .invalid:
			// Provider not installed/enabled

			poll = false

			error = Errors.couldNotConnect

		case .connecting:
			poll = true
			commTunnel()

		case .connected:
			poll = false

		case .reasserting:
			// Circuit reestablishing
			poll = true
			commTunnel()

		case .disconnecting:
			// Circuit disestablishing
			poll = false

		case .disconnected:
			// Circuit not established
			poll = false

		default:
			assert(session == nil)
		}

		postChange()
	}

	private func commTunnel() {
		if (session?.status ?? .invalid) != .invalid {
			do {
				try session?.sendProviderMessage(Data()) { response in
					if let response = response {
						if let response = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(response) as? [Message] {
							for message in response {
								if let pm = message as? ProgressMessage {
									print("[\(String(describing: type(of: self)))] ProgressMessage=\(pm.progress)")

									DispatchQueue.main.async {
										NotificationCenter.default.post(name: .vpnProgress, object: pm.progress)
									}
								}
								else if message is ConfigChangedMessage {
									print("[\(String(describing: type(of: self)))] ConfigChangedMessage")

									DispatchQueue.main.async {
										NotificationCenter.default.post(name: .vpnStatusChanged, object: nil)
									}
								}
							}
						}
					}
				}
			}
			catch {
				NSLog("[\(String(describing: type(of: self)))] "
					  + "Could not establish communications channel with extension. "
					  + "Error: \(error)")
			}

			if poll {
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: self.commTunnel)
			}
		}
		else {
			NSLog("[\(String(describing: type(of: self)))] "
				  + "Could not establish communications channel with extension. "
				  + "VPN configuration does not exist or is not enabled. "
				  + "No further actions will be taken.")

			error = Errors.couldNotConnect

			postChange()
		}
	}

	func sendMessage<T>(_ message: Message, _ callback: @escaping ((_ payload: T?, _ error: Error?) -> Void)) {
		let request: Data

		do {
			request = try NSKeyedArchiver.archivedData(withRootObject: message, requiringSecureCoding: true)
		}
		catch let error {
			return callback(nil, error)
		}

		do {
			try session?.sendProviderMessage(request) { response in
				guard let response = response else {
					return callback(nil, nil)
				}

				do {
					if let error = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(response) as? Error {
						callback(nil, error)
					}
					else if T.self is Data.Type {
						callback(response as? T, nil)
					}
					else {
						let payload = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(response) as? T
						callback(payload, nil)
					}
				}
				catch let error {
					callback(nil, error)
				}
			}
		}
		catch let error {
			callback(nil, error)
		}
	}

	private func postChange() {
		DispatchQueue.main.async {
			NotificationCenter.default.post(name: .vpnStatusChanged, object: self)
		}
	}
}

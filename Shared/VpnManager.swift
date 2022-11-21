//
//  VpnManager.swift
//  Orbot
//
//  Created by Benjamin Erhart on 20.05.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import NetworkExtension
import Tor

extension Notification.Name {
	static let vpnStatusChanged = Notification.Name("vpn-status-changed")
	static let vpnProgress = Notification.Name("vpn-progress")
}

extension NEVPNStatus: CustomStringConvertible {
	public var description: String {
		switch self {
		case .connected:
			return NSLocalizedString("connected", comment: "")

		case .connecting:
			return NSLocalizedString("connecting", comment: "")

		case .disconnected:
			return NSLocalizedString("disconnected", comment: "")

		case .disconnecting:
			return NSLocalizedString("disconnecting", comment: "")

		case .invalid:
			return NSLocalizedString("invalid", comment: "")

		case .reasserting:
			return NSLocalizedString("reasserting", comment: "")

		@unknown default:
			return NSLocalizedString("unknown", comment: "")
		}
	}
}

class VpnManager {

	typealias Completed = (_ success: Bool) -> Void

	enum ConfStatus: CustomStringConvertible {
		var description: String {
			switch self {
			case .notInstalled:
				return NSLocalizedString("not installed", comment: "")

			case .disabled:
				return NSLocalizedString("disabled", comment: "")

			case .enabled:
				return NSLocalizedString("enabled", comment: "")
			}
		}

		case notInstalled
		case disabled
		case enabled
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

	var confStatus: ConfStatus {
#if DEBUG
		if Config.screenshotMode {
			return .enabled
		}
#endif

		return manager == nil ? .notInstalled : manager!.isEnabled ? .enabled : .disabled
	}

	var sessionStatus: NEVPNStatus {
#if DEBUG
		if Config.screenshotMode {
			return .connected
		}
#endif

		if confStatus == .notInstalled {
			return .invalid
		}

		return session?.status ?? .disconnected
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
		switch sessionStatus {
		case .connecting, .connected, .reasserting:
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

	func connect() {
		let completed: Completed = { [weak self] success in
			guard success,
				  let session = self?.session
			else {
				self?.error = Errors.noConfiguration

				self?.postChange()

				return
			}

			DispatchQueue.main.async {
				guard let self = self else {
					return
				}

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
		switch sessionStatus {
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

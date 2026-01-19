//
//  BasePTProvider.swift
//  TorVPN
//
//  Created by Benjamin Erhart on 20.05.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import NetworkExtension
import WidgetKit

#if os(macOS)
import IPtProxyUI
#endif

class BasePTProvider: NEPacketTunnelProvider {

	enum Errors: LocalizedError {
		case tunnelFdNotFound
		case socksPortUnparsable
		case dnsPortUnparsable

		var errorDescription: String? {
			switch self {
			case .tunnelFdNotFound:
				return "utun file descriptor could not be found."
			case .socksPortUnparsable:
				return "Error while trying to parse the provided Tor SOCKS5 port."
			case .dnsPortUnparsable:
				return "Error while trying to parse the provided Tor DNS port."
			}
		}
	}

	private static var messageQueue = [Message]()


	var tunnelFd: Int32? {
		for fd: Int32 in 0 ... 1024 {
			var buf = [CChar](repeating: 0, count: Int(IFNAMSIZ))
			var len = socklen_t(buf.count)

			if getsockopt(fd, 2 /* IGMP */, 2, &buf, &len) == 0 &&
				String(cString: buf).hasPrefix("utun")
			{
				return fd
			}
		}

		// This will crash on newer iOS, hence the check. Ignore the warning, that's a linter bug.
		if packetFlow.responds(to: Selector("socket.fileDescriptor")) {
			return packetFlow.value(forKey: "socket.fileDescriptor") as? Int32
		}

		return nil
	}


	private var hostHandler: ((Data?) -> Void)?

	private var transport = Settings.transport

	private var connectionGuard: DispatchSourceTimer?
	private var connectionTimeout = DispatchTime.now()

	private var oldProgress: Int = -1


	override init() {
		super.init()

		NSKeyedUnarchiver.setClass(CloseCircuitsMessage.self, forClassName:
									"Orbot.\(String(describing: CloseCircuitsMessage.self))")

		NSKeyedUnarchiver.setClass(CloseCircuitsMessage.self, forClassName:
									"Orbot_Mac.\(String(describing: CloseCircuitsMessage.self))")

		NSKeyedUnarchiver.setClass(GetCircuitsMessage.self, forClassName:
									"Orbot.\(String(describing: GetCircuitsMessage.self))")

		NSKeyedUnarchiver.setClass(GetCircuitsMessage.self, forClassName:
									"Orbot_Mac.\(String(describing: GetCircuitsMessage.self))")

		NSKeyedUnarchiver.setClass(ConfigChangedMessage.self, forClassName:
									"Orbot.\(String(describing: ConfigChangedMessage.self))")

		NSKeyedUnarchiver.setClass(ConfigChangedMessage.self, forClassName:
									"Orbot_Mac.\(String(describing: ConfigChangedMessage.self))")

		NSKeyedUnarchiver.setClass(DebugMessage.self, forClassName:
									"Orbot.\(String(describing: DebugMessage.self))")

		NSKeyedUnarchiver.setClass(DebugMessage.self, forClassName:
									"Orbot_Mac.\(String(describing: DebugMessage.self))")

		Settings.stateLocation = FileManager.default.ptDir!
}


	override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void)
	{
		updateWidget()

#if USE_ONIONMASQ
		let addressRange = "169.254.42.1"
		let dnsIp = "169.254.42.53"
#else
		let addressRange = "192.168.20.2"
		let dnsIp = "192.168.20.1"
#endif

		let ipv4 = NEIPv4Settings(addresses: [addressRange], subnetMasks: ["255.255.255.0"])
		ipv4.includedRoutes = [NEIPv4Route.default()]

		let ipv6 = NEIPv6Settings(addresses: ["fd00::0001"], networkPrefixLengths: [48])
		ipv6.includedRoutes = [NEIPv6Route.default()]

		let dns = NEDNSSettings(servers: [dnsIp])
		// https://developer.apple.com/forums/thread/116033
		// Mention special Tor domains here, so the OS doesn't drop onion domain
		// resolve requests immediately.
		dns.matchDomains = ["", "onion", "exit"]

		let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: TorManager.localhost)
		settings.ipv4Settings = ipv4
		settings.ipv6Settings = ipv6
		settings.dnsSettings = dns

		setTunnelNetworkSettings(settings) { error in
			if let error = error {
				self.log("#startTunnel error=\(error)")

				self.updateWidget()
				completionHandler(error)

				return
			}

			var completionHandlerCalled = false

#if os(iOS)
			// Avoid getting killed by the a new watchdog timer built
			// into iOS 16.5 and up: If we don't call the `completionHandler`
			// within a minute, we get killed again.
			// Esp. Snowflake starts are often long and winding, and
			// take more than one minute. See #77
			DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 55) {
				if !completionHandlerCalled {
					completionHandlerCalled = true

					completionHandler(nil)
				}
			}
#endif

			let completion = { (error: Error?, socksAddr: String?, dnsAddr: String?) -> Void in
				if let error = error {
					self.updateWidget()

					if !completionHandlerCalled {
						completionHandlerCalled = true

						completionHandler(error)
					}

					return
				}

				do {
					try self.startTun2Socks(socksAddr: socksAddr, dnsAddr: dnsAddr)
				}
				catch {
					self.log("#startTunnel error=\(error)")

					if !completionHandlerCalled {
						completionHandlerCalled = true

						completionHandler(error)
					}
					else {
						self.stopTunnel(with: .noNetworkAvailable) {
							// Ignored
						}
					}

					return
				}

				self.log("#startTunnel successful")

				self.updateWidget()

				if !completionHandlerCalled {
					completionHandlerCalled = true

					completionHandler(nil)
				}
			}

			self.startTransportAndTor(completion)
		}
	}

	override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
		log("#stopTunnel reason=\(reason)")

		TorManager.shared.stop()

		transport.stop()

		stopTun2Socks()

// This is only supported on iOS, currently.
#if os(iOS)
		WebServer.shared.stop()
#endif

		updateWidget()
		completionHandler()
	}

	override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
		let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: messageData)
		let request = unarchiver?.decodeObject(of: Message.self, forKey: NSKeyedArchiveRootObjectKey)

		if !messageData.isEmpty || request != nil {
			log("#handleAppMessage messageData=\(messageData), request=\(String(describing: request))")
		}

		if request is GetCircuitsMessage {
			TorManager.shared.getCircuits { circuits in
				completionHandler?(Self.archive(circuits))
			}

			return
		}

		if let request = request as? CloseCircuitsMessage {
			TorManager.shared.close(request.circuits) { success in
				completionHandler?(Self.archive(success))
			}

			return
		}

		if request is ConfigChangedMessage {
			let newTransport = Settings.transport

			// If the old transport is snowflake and the new one not, stop that.
			if (transport == .snowflake || transport == .snowflakeAmp) && newTransport != .snowflake && newTransport != .snowflakeAmp {
				transport.stop()
			}
			// If the old transport is obfs4 and the new one not, stop that.
			else if (transport == .obfs4 || transport == .custom) && newTransport != .obfs4 && newTransport != .custom {
				transport.stop()
			}

			transport = newTransport

			startTransportAndTor { error, socksAddr, dnsAddr in
				completionHandler?(Self.archive(error ?? true))
			}

			return
		}

		// Wait for progress updates.
		DispatchQueue.main.async {
			self.hostHandler = completionHandler
		}

		if !Self.messageQueue.isEmpty {
			sendMessages()
		}
	}


	// MARK: Abstract Methods

	func startTun2Socks(socksAddr: String?, dnsAddr: String?) throws {
		assertionFailure("Method needs to be implemented in subclass!")
	}

	func stopTun2Socks() {
		assertionFailure("Method needs to be implemented in subclass!")
	}


	// MARK: Private Methods

	@objc private func sendMessages() {
		DispatchQueue.main.async {
			if let handler = self.hostHandler {
				let response = Self.archive(Self.messageQueue)

				Self.messageQueue.removeAll()

				self.log("#sendMessages response=\(String(describing: response))")

				handler(response)

				self.hostHandler = nil
			}
		}
	}

	private class func archive(_ root: Any) -> Data? {
		return try? NSKeyedArchiver.archivedData(withRootObject: root, requiringSecureCoding: true)
	}

	private func startTransportAndTor(_ completion: @escaping (Error?, _ socksAddr: String?, _ dnsAddr: String?) -> Void) {
		stopConnectionGuard()

		// Since IPtProxyUI.Settings use `UserDefaults.standard` as source, instead of
		// `UserDefaults(suiteName: Config.groupId)` as Orbot does, `custom`
		// bridge lines cannot be resolved by `IPtProxyUI.Transport` automatically.
		// So we need to hand them over manually.
		// `Transport.customBridges` need to be set before `start`, otherwise, `IPtProxyUI`
		// cannot determine, which transport to start and will do nothing.
		Transport.customBridges = Settings.customBridges
		Transport.proxy = Settings.proxy

		transport.logFile?.truncate()

		do {
			try transport.start()
		}
		catch {
			return completion(error, nil, nil)
		}

#if os(macOS)
		NotificationCenter.default.addObserver(self, selector: #selector(transportErrored), name: .iPtProxyTransportErrored, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(transportConnected), name: .iPtProxyTransportConnected, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(transportStopped), name: .iPtProxyTransportStopped, object: nil)
#endif

		oldProgress = -1

		TorManager.shared.start(transport, packetFlow, { [weak self] progress, summary in
			guard let progress = progress else {
				return
			}

			if progress > self?.oldProgress ?? -1 {
				self?.connectionAlive()
				self?.oldProgress = progress
			}

			Self.messageQueue.append(ProgressMessage(Float(progress) / 100, summary))

			self?.sendMessages()
		}, { [weak self] error, socksAddr, dnsAddr in
			self?.stopConnectionGuard()

#if os(macOS)
			if let self {
				NotificationCenter.default.removeObserver(self, name: .iPtProxyTransportErrored, object: nil)
				NotificationCenter.default.removeObserver(self, name: .iPtProxyTransportConnected, object: nil)
				NotificationCenter.default.removeObserver(self, name: .iPtProxyTransportStopped, object: nil)
			}
#endif

			// Since we seem to have a working connection now, disable smart connect.
			if error == nil && Settings.smartConnect {
				Settings.smartConnect = false
			}

			completion(error, socksAddr, dnsAddr)
		})


		if Settings.smartConnect {

			// Assume everything's fine for the next 30 seconds.
			connectionAlive()

			// Create new connection guard.
			connectionGuard = DispatchSource.makeTimerSource(queue: .global(qos: .background))
			connectionGuard?.schedule(deadline: .now() + 1, repeating: .seconds(1))

			// If Tor's progress doesn't move within 30 seconds, try (another) bridge.
			connectionGuard?.setEventHandler { [weak self] in
				guard let self = self, DispatchTime.now() > self.connectionTimeout else {
					return
				}

				self.connectionAlive()

				var connected = false

				repeat {
					switch self.transport {

						// If direct connection didn't work, try Snowflake bridge.
					case .none:
						self.transport = .snowflake

						self.transport.logFile?.truncate()

						do {
							try self.transport.start()
							connected = true
						}
						catch {
							self.log(error.localizedDescription)
						}

						// If Snowflake didn't work, try custom or default Obfs4 bridges.
					case .snowflake, .snowflakeAmp:
						self.transport.stop()

						if !(Settings.customBridges?.isEmpty ?? true) {
							self.transport = .custom
						}
						else {
							self.transport = .obfs4
						}

						self.transport.logFile?.truncate()

						do {
							try self.transport.start()
							connected = true
						}
						catch {
							self.log(error.localizedDescription)
						}

						// If custom Obfs4 bridges didn't work, try default ones.
					case .custom:
						self.transport.stop()

						self.transport = .obfs4

						self.transport.logFile?.truncate()

						do {
							try self.transport.start()
							connected = true
						}
						catch {
							self.log(error.localizedDescription)
						}

						// If Obfs4 bridges didn't work, give up.
					default:
						self.stopConnectionGuard()

						TorManager.shared.stop()

						self.transport.stop()

						completion(TorManager.Errors.smartConnectFailed, nil, nil)
						return
					}
				}
				while !connected

				TorManager.shared.updateConfig(self.transport)

				Settings.transport = self.transport
				Self.messageQueue.append(ConfigChangedMessage())
				self.sendMessages()
			}

			connectionGuard?.resume()
		}


// This is only supported on iOS, currently.
#if os(iOS)
		do {
			try WebServer.shared.start()
		}
		catch {
			log(error.localizedDescription)
		}
#endif
	}

	@objc
	private func transportErrored(_ notification: Notification) {
		Task {
			if let error = (notification.object as? [Transport])?.compactMap({ $0.error }).first {
				Self.messageQueue.append(
					ProgressMessage(Float(max(0, oldProgress)) / 100, error.localizedDescription))
			}
		}
	}

	@objc
	private func transportConnected(_ notification: Notification) {
		Task {
			Self.messageQueue.append(
				ProgressMessage(Float(max(0, oldProgress)) / 100,
								NSLocalizedString("Bridge connected", comment: "")))
		}
	}

	@objc
	private func transportStopped(_ notification: Notification) {
		Task {
			let error = (notification.object as? [Transport])?.compactMap({ $0.error }).first

			Self.messageQueue.append(
				ProgressMessage(Float(max(0, oldProgress)) / 100,
								error?.localizedDescription ?? NSLocalizedString("Bridge stopped", comment: "")))
		}
	}

	/**
	 Give connection guard another 30 seconds to assume everything's ok.
	 */
	private func connectionAlive() {
		connectionTimeout = .now() + Settings.smartConnectTimeout
	}

	private func stopConnectionGuard() {
		connectionGuard?.cancel()
		connectionGuard = nil
	}

	private func updateWidget() {
		WidgetCenter.shared.reloadAllTimelines()
	}


	// MARK: Logging

	func log(_ message: String) {
		Logger.log(message, to: Logger.vpnLogFile)
	}
}

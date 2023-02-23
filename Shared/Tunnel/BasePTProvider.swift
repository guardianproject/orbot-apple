//
//  BasePTProvider.swift
//  TorVPN
//
//  Created by Benjamin Erhart on 20.05.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import NetworkExtension


class BasePTProvider: NEPacketTunnelProvider {

	private static var messageQueue = [Message]()


	var tunnelFd: Int32? {
		var buf = [CChar](repeating: 0, count: Int(IFNAMSIZ))

		for fd: Int32 in 0 ... 1024 {
			var len = socklen_t(buf.count)

			if getsockopt(fd, 2 /* IGMP */, 2, &buf, &len) == 0 && String(cString: buf).hasPrefix("utun") {
				return fd
			}
		}

		return packetFlow.value(forKey: "socket.fileDescriptor") as? Int32
	}


	private var hostHandler: ((Data?) -> Void)?

	private var transport = Settings.transport

	private var connectionGuard: DispatchSourceTimer?
	private var connectionTimeout = DispatchTime.now()


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
		let ipv4 = NEIPv4Settings(addresses: ["192.168.20.2"], subnetMasks: ["255.255.255.0"])
		ipv4.includedRoutes = [NEIPv4Route.default()]

		let ipv6 = NEIPv6Settings(addresses: ["FC00::0001"], networkPrefixLengths: [7])
		ipv6.includedRoutes = [NEIPv6Route.default()]

		let dns = NEDNSSettings(servers: ["192.168.20.1"])
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
				return completionHandler(error)
			}

			let completion = { (error: Error?, socksAddr: String?, dnsAddr: String?) -> Void in
				if let error = error {
					return completionHandler(error)
				}

				self.startTun2Socks(socksAddr: socksAddr, dnsAddr: dnsAddr)

				self.log("#startTunnel successful")

				completionHandler(nil)
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

		completionHandler()
	}

	override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
		let request = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(messageData)

		log("#handleAppMessage messageData=\(messageData), request=\(String(describing: request))")

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
		}

		// Wait for progress updates.
		hostHandler = completionHandler
	}


	// MARK: Abstract Methods

	func startTun2Socks(socksAddr: String?, dnsAddr: String?) {
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

		if Logger.ENABLE_LOGGING {
			transport.logFile?.truncate()
		}
		transport.start(log: Logger.ENABLE_LOGGING)

		var oldProgress = -1

		TorManager.shared.start(transport, { [weak self] progress in
			guard let progress = progress else {
				return
			}

			if progress > oldProgress {
				self?.connectionAlive()
				oldProgress = progress
			}

			Self.messageQueue.append(ProgressMessage(Float(progress) / 100))

			self?.sendMessages()
		}, { [weak self] error, socksAddr, dnsAddr in
			self?.stopConnectionGuard()

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

				switch self.transport {

				// If direct connection didn't work, try Snowflake bridge.
				case .none:
					self.transport = .snowflake

					if Logger.ENABLE_LOGGING {
						self.transport.logFile?.truncate()
					}
					self.transport.start(log: Logger.ENABLE_LOGGING)

				// If Snowflake didn't work, try custom or default Obfs4 bridges.
				case .snowflake, .snowflakeAmp:
					self.transport.stop()

					if !(Settings.customBridges?.isEmpty ?? true) {
						self.transport = .custom
					}
					else {
						self.transport = .obfs4
					}

					if Logger.ENABLE_LOGGING {
						self.transport.logFile?.truncate()
					}
					self.transport.start(log: Logger.ENABLE_LOGGING)

				// If custom Obfs4 bridges didn't work, try default ones.
				case .custom:
					self.transport = .obfs4

				// If Obfs4 bridges didn't work, give up.
				case .obfs4:
					self.stopConnectionGuard()

					TorManager.shared.stop()

					self.transport.stop()

					completion(TorManager.Errors.smartConnectFailed, nil, nil)
					return
				}

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


	// MARK: Logging

	func log(_ message: String) {
		Logger.log(message, to: Logger.vpnLogFile)
	}
}

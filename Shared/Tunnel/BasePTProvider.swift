//
//  BasePTProvider.swift
//  TorVPN
//
//  Created by Benjamin Erhart on 20.05.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import NetworkExtension

#if os(iOS)
import IPtProxy
#endif

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

	private var bridge = Settings.bridge


	override init() {
		super.init()

		NSKeyedUnarchiver.setClass(CloseCircuitsMessage.self, forClassName:
									"Orbot.\(String(describing: CloseCircuitsMessage.self))")

		NSKeyedUnarchiver.setClass(GetCircuitsMessage.self, forClassName:
									"Orbot.\(String(describing: GetCircuitsMessage.self))")

		NSKeyedUnarchiver.setClass(CloseCircuitsMessage.self, forClassName:
									"Orbot_Mac.\(String(describing: CloseCircuitsMessage.self))")

		NSKeyedUnarchiver.setClass(GetCircuitsMessage.self, forClassName:
									"Orbot_Mac.\(String(describing: GetCircuitsMessage.self))")

		NSKeyedUnarchiver.setClass(ConfigChangedMessage.self, forClassName:
									"Orbot.\(String(describing: ConfigChangedMessage.self))")

		NSKeyedUnarchiver.setClass(ConfigChangedMessage.self, forClassName:
									"Orbot_Mac.\(String(describing: ConfigChangedMessage.self))")
	}


	override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void)
	{
		let ipv4 = NEIPv4Settings(addresses: ["192.168.20.2"], subnetMasks: ["255.255.255.0"])
		ipv4.includedRoutes = [NEIPv4Route.default()]

		let ipv6 = NEIPv6Settings(addresses: ["FC00::0001"], networkPrefixLengths: [7])
		ipv6.includedRoutes = [NEIPv6Route.default()]

		let dns = NEDNSSettings(servers: ["1.1.1.1"])
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

			self.startBridgeAndTor(completion)
		}
	}

	override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
		log("#stopTunnel reason=\(reason)")

		TorManager.shared.stop()

#if os(iOS)
		switch bridge {
		case .obfs4, .custom:
			IPtProxyStopObfs4Proxy()

		case .snowflake:
			IPtProxyStopSnowflake()

		default:
			break
		}
#endif

		stopTun2Socks()

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
			let newBridge = Settings.bridge

			// If the old bridge is snowflake, stop that. (The new one certainly isn't!)
			if bridge == .snowflake && newBridge != .snowflake {
				IPtProxyStopSnowflake()
			}
			// If the old bridge is obfs4 and the new one not, stop that.
			else if (bridge == .obfs4 || bridge == .custom) && newBridge != .obfs4 && newBridge != .custom {
				IPtProxyStopObfs4Proxy()
			}

			bridge = newBridge

			startBridgeAndTor { error, socksAddr, dnsAddr in
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

	private func startBridgeAndTor(_ completion: @escaping (Error?, _ socksAddr: String?, _ dnsAddr: String?) -> Void) {
#if os(iOS)
		switch bridge {
		case .obfs4, .custom:
#if DEBUG
			let ennableLogging = true
#else
			let ennableLogging = false
#endif

			IPtProxyStartObfs4Proxy("DEBUG", ennableLogging, true, nil)

		case .snowflake:
			IPtProxyStartSnowflake(
				"stun:stun.l.google.com:19302,stun:stun.voip.blackberry.com:3478,stun:stun.altar.com.pl:3478,stun:stun.antisip.com:3478,stun:stun.bluesip.net:3478,stun:stun.dus.net:3478,stun:stun.epygi.com:3478,stun:stun.sonetel.com:3478,stun:stun.sonetel.net:3478,stun:stun.stunprotocol.org:3478,stun:stun.uls.co.za:3478,stun:stun.voipgate.com:3478,stun:stun.voys.nl:3478",
				"https://snowflake-broker.torproject.net.global.prod.fastly.net/",
				"cdn.sstatic.net", nil, true, false, true, 1)

		default:
			break
		}
#endif

		TorManager.shared.start(bridge, { progress in
			Self.messageQueue.append(ProgressMessage(Float(progress) / 100))
			self.sendMessages()
		}, completion)

	}


	// MARK: Logging

	func log(_ message: String) {
		Logger.log(message, to: Logger.vpnLogfile)
	}
}

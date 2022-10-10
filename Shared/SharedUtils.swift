//
//  MainViewController+Shared.swift
//  Orbot
//
//  Created by Benjamin Erhart on 30.09.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import Foundation
import IPtProxyUI
import NetworkExtension
import Tor

class SharedUtils: BridgesConfDelegate {

	#if os(macOS)
	typealias Color = NSColor
	#else
	typealias Color = UIColor
	#endif


	public static var torConfUrl: URL {
		URL(string: "https://2019.www.torproject.org/docs/tor-manual.html")!
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
		VpnManager.shared.configChanged()
	}


	// MARK: Shared Methods

	static func control(startOnly: Bool) {

		// Enable, if disabled.
		if VpnManager.shared.confStatus == .disabled {
			return VpnManager.shared.enable { success in
				if success && VpnManager.shared.confStatus == .enabled {
					control(startOnly: startOnly)
				}
			}
		}

		if startOnly && ![NEVPNStatus.disconnected, .disconnecting].contains(VpnManager.shared.sessionStatus) {
			return
		}

		// Install first, if not installed.
		else if VpnManager.shared.confStatus == .notInstalled {
			return VpnManager.shared.install()
		}

		switch VpnManager.shared.sessionStatus {
		case .connected, .connecting:
			VpnManager.shared.disconnect(explicit: true)

		case .disconnected, .disconnecting:
			VpnManager.shared.connect()

		default:
			break
		}
	}

	static func updateUi(_ notification: Notification? = nil) -> (statusIcon: String, buttonTitle: String, statusText: NSMutableAttributedString) {
		let statusIcon: String
		let buttonTitle: String
		var statusText: NSMutableAttributedString

		switch VpnManager.shared.sessionStatus {
		case .connected, .connecting, .reasserting:
			statusIcon = Settings.onionOnly ? "TorOnionOnly" : "TorOn"
			buttonTitle = NSLocalizedString("Stop", comment: "")

		case .invalid:
			statusIcon = "TorOff"
			buttonTitle = NSLocalizedString("Install", comment: "")

		default:
			statusIcon = "TorOff"
			buttonTitle = NSLocalizedString("Start", comment: "")
		}

		if let error = VpnManager.shared.error {
			statusText = NSMutableAttributedString(string: error.localizedDescription,
												   attributes: [.foregroundColor: Color.systemRed])
		}
		else if VpnManager.shared.confStatus != .enabled {
			statusText = NSMutableAttributedString(string: VpnManager.shared.confStatus.description)
		}
		else {
			statusText = NSMutableAttributedString(string: VpnManager.shared.sessionStatus.description)

			switch VpnManager.shared.sessionStatus {
			case .connected, .connecting, .reasserting:
				let space = NSAttributedString(string: " ")
				let transport = Settings.transport

				if transport != .none {
					statusText = NSMutableAttributedString(string: String(
						format: NSLocalizedString("%1$@ via %2$@", comment: ""),
						VpnManager.shared.sessionStatus.description, transport.description))
				}

				if Settings.onionOnly {
					statusText.append(space)
					statusText.append(NSAttributedString(string: "(\(NSLocalizedString("Onion-only Mode", comment: "")))",
														 attributes: [.foregroundColor : Color.systemRed]))
				}
				else if Settings.bypassPort != nil {
					statusText.append(space)
					statusText.append(NSAttributedString(string: "(\(NSLocalizedString("Bypass", comment: "")))",
														 attributes: [.foregroundColor : Color.systemRed]))
				}

				if notification?.name == .vpnProgress,
				   let raw = notification?.object as? Float,
				   let progress = Formatters.format(value: raw)
				{
					statusText.append(space)
					statusText.append(NSAttributedString(string: progress))
				}

			default:
				break
			}
		}

		return (statusIcon, buttonTitle, statusText)
	}

	static func getCircuits(_ completed: @escaping (_ text: String) -> Void) {
		VpnManager.shared.getCircuits { circuits, error in
			let circuits = TorCircuit.filter(circuits)

			var text = ""

			var i = 1

			for c in circuits {
				text += "Circuit \(c.circuitId ?? String(i))\n"

				var j = 1

				for n in c.nodes ?? [] {
					var country = n.localizedCountryName ?? n.countryCode ?? ""

					if !country.isEmpty {
						country = " (\(country))"
					}

					text += "\(j): \(n.nickName ?? n.fingerprint ?? n.ipv4Address ?? n.ipv6Address ?? "unknown node")\(country)\n"

					j += 1
				}

				text += "\n"

				i += 1
			}

			completed(text)
		}
	}
}

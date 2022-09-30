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

extension MainViewController : BridgesConfDelegate {

	#if os(macOS)
	typealias Color = NSColor
	#else
	typealias Color = UIColor
	#endif


	// MARK: Shared Strings
	
	public var settingsText: String {
		NSLocalizedString("Settings", comment: "")
	}

	public var newCircuitsText: String {
		NSLocalizedString("Build new Circuits", comment: "")
	}

	public var versionText: String {
		String(format: NSLocalizedString("Version %@, Build %@", comment: ""),
			   Bundle.main.version, Bundle.main.build)
	}

	public var logLabelText: String {
		NSLocalizedString("Log", comment: "")
	}

	public var authCookiesText: String {
		NSLocalizedString("Auth Cookies", comment: "")
	}

	public var bridgeConfText: String {
		NSLocalizedString("Bridge Configuration", bundle: Bundle.iPtProxyUI, comment: "#bc-ignore!")
	}

	public var errorText: String {
		NSLocalizedString("Error", bundle: Bundle.iPtProxyUI, comment: "#bc-ignore!")
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

	func control(startOnly: Bool) {

		// Enable, if disabled.
		if VpnManager.shared.confStatus == .disabled {
			return VpnManager.shared.enable { [weak self] success in
				if success && VpnManager.shared.confStatus == .enabled {
					self?.control(startOnly: startOnly)
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
			VpnManager.shared.disconnect()

		case .disconnected, .disconnecting:
			VpnManager.shared.connect()

		default:
			break
		}
	}

	func _updateUi(_ notification: Notification? = nil) -> (statusIcon: String, buttonTitle: String, statusText: NSMutableAttributedString) {
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
}

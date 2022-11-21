//
//  MainViewController+Shared.swift
//  Orbot
//
//  Created by Benjamin Erhart on 30.09.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import Foundation
import IPtProxy
import IPtProxyUI
import NetworkExtension
import Tor

class SharedUtils: NSObject, BridgesConfDelegate, IPtProxySnowflakeClientConnectedProtocol {

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


	// MARK: IPtProxySnowflakeClientConnectedProtocol

	private static var selfInstance = SharedUtils()

	func connected() {
		Settings.snowflakesHelped += 1

		NotificationCenter.default.post(name: .vpnStatusChanged, object: nil)
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

	static func controlSnowflakeProxy() {
		if IPtProxyIsSnowflakeProxyRunning() {
			IPtProxyStopSnowflakeProxy()
		}
		else {
			IPtProxyStartSnowflakeProxy(1, nil, nil, nil, nil,
										FileManager.default.sfpLogFile?.truncate().path,
										false, false, selfInstance)
		}

		NotificationCenter.default.post(name: .vpnStatusChanged, object: nil)
	}


	static func updateUi(_ notification: Notification? = nil) -> (statusIcon: String, buttonTitle: String, statusText: NSMutableAttributedString, sfpText: String) {
		let statusIcon: String
		let buttonTitle: String
		var statusText: NSMutableAttributedString

		switch VpnManager.shared.sessionStatus {
		case .connected:
			statusIcon = Settings.onionOnly ? .imgOrbieOnionOnly : .imgOrbieOn
			buttonTitle = NSLocalizedString("Stop", comment: "")

		case .connecting, .reasserting:
			statusIcon = .imgOrbieStarting
			buttonTitle = NSLocalizedString("Stop", comment: "")

		case .invalid:
			statusIcon = .imgOrbieDead
			buttonTitle = NSLocalizedString("Install", comment: "")

		default:
			statusIcon = .imgOrbieOff
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

			if VpnManager.shared.isConnected {
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
				   let progress = Formatters.formatPercent(raw)
				{
					statusText.append(space)
					statusText.append(NSAttributedString(string: progress))
				}
			}
		}

		let sfpText = String(
			format: IPtProxyIsSnowflakeProxyRunning() ? L10n.snowflakeProxyStarted : L10n.snowflakeProxyStopped,
			Formatters.format(Settings.snowflakesHelped))

		return (statusIcon, buttonTitle, statusText, sfpText)
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

	static func clearTorCache() {
		let fm = FileManager.default

		guard let torDir = fm.torDir,
			  let enumerator = fm.enumerator(at: torDir, includingPropertiesForKeys: [.isDirectoryKey])
		else {
			return
		}

		for case let file as URL in enumerator {
			if (try? file.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false {
				if file == fm.torAuthDir {
					enumerator.skipDescendants()
				}

				continue
			}

			do {
				try fm.removeItem(at: file)

				print("File deleted: \(file.path)")
			}
			catch {
				print("File could not be deleted: \(file.path)")
			}
		}
	}


#if DEBUG
	static func addScreenshotDummies() {
		guard Config.screenshotMode, let authDir = FileManager.default.torAuthDir else {
			return
		}

		do {
			try "6gk626a5xm3gdyrbezfhiptzegvvc62c3k6y3xbelglgtgqtbai5liqd:descriptor:x25519:EJOYJMYKNS6TYTQ2RSPZYBSBR3RUZA5ZKARKLF6HXVXHTIV76UCQ"
				.write(to: authDir.appendingPathComponent("6gk626a5xm3gdyrbezfhiptzegvvc62c3k6y3xbelglgtgqtbai5liqd.auth_private"),
					   atomically: true, encoding: .utf8)

			try "jtb2cwibhkok4f2xejfqbsjb2xcrwwcdj77bjvhofongraxvumudyoid:descriptor:x25519:KC2VJ5JLZ5QLAUUZYMRO4R3JSOYM3TBKXDUMAS3D5BEI5IPYUI4A"
				.write(to: authDir.appendingPathComponent("jtb2cwibhkok4f2xejfqbsjb2xcrwwcdj77bjvhofongraxvumudyoid.auth_private"),
					   atomically: true, encoding: .utf8)

			try "pqozr7dey5yellqfwzjppv4q25zbzbwligib7o7g5s6bvrltvy3lfdid:descriptor:x25519:ZHXT5IO2OMJKH3HKPDYDNNXXIPJCXR5EG6MGLQNC56GAF2C75I5A"
				.write(to: authDir.appendingPathComponent("pqozr7dey5yellqfwzjppv4q25zbzbwligib7o7g5s6bvrltvy3lfdid.auth_private"),
					   atomically: true, encoding: .utf8)
		}
		catch {
			print(error)
		}
	}
#endif
}

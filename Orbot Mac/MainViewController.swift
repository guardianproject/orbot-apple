//
//  MainViewController.swift
//  Orbot Mac
//
//  Created by Benjamin Erhart on 11.08.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import Cocoa
import IPtProxyUI
import NetworkExtension

class MainViewController: NSViewController {

	@IBOutlet weak var controlBt: NSButton!
	@IBOutlet weak var statusLb: NSTextField!

	@IBOutlet weak var versionLb: NSTextField! {
		didSet {
			versionLb.stringValue = String(
				format: NSLocalizedString("Version %@, Build %@", comment: ""),
				Bundle.main.version, Bundle.main.build)
		}
	}


	override func viewDidLoad() {
		super.viewDidLoad()

		let nc = NotificationCenter.default

		nc.addObserver(self, selector: #selector(updateUi), name: .vpnStatusChanged, object: nil)
		nc.addObserver(self, selector: #selector(updateUi), name: .vpnProgress, object: nil)

		updateUi()
	}

	override func viewDidAppear() {
		super.viewDidAppear()

		view.window?.title = Bundle.main.displayName
	}

	override var representedObject: Any? {
		didSet {
			// Update the view, if already loaded.
		}
	}


	// MARK: Actions

	@IBAction func control(_ sender: Any) {
		control(startOnly: false)
	}

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


	// MARK: Observers

	@objc func updateUi(_ notification: Notification? = nil) {

		switch VpnManager.shared.sessionStatus {
		case .connected, .connecting, .reasserting:
			controlBt.image = Settings.onionOnly
				? NSImage(named: "TorOnionOnly") : NSImage(named: "TorOn")

			controlBt.setTitle(NSLocalizedString("Stop", comment: ""))

		case .invalid:
			controlBt.image = NSImage(named: "TorOff")
			controlBt.setTitle(NSLocalizedString("Install", comment: ""))

		default:
			controlBt.image = NSImage(named: "TorOff")
			controlBt.setTitle(NSLocalizedString("Start", comment: ""))
		}

		if let error = VpnManager.shared.error {
			statusLb.textColor = .systemRed
			statusLb.stringValue = error.localizedDescription
		}
		else if VpnManager.shared.confStatus != .enabled {
			statusLb.textColor = .white
			statusLb.stringValue = VpnManager.shared.confStatus.description
		}
		else {
			var statusText = NSMutableAttributedString(string: VpnManager.shared.sessionStatus.description)

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
														 attributes: [.foregroundColor : NSColor.systemRed]))
				}
				else if Settings.bypassPort != nil {
					statusText.append(space)
					statusText.append(NSAttributedString(string: "(\(NSLocalizedString("Bypass", comment: "")))",
														 attributes: [.foregroundColor : NSColor.systemRed]))
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

			statusLb.textColor = .white
			statusLb.attributedStringValue = statusText
		}
	}
}

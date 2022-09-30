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

class MainViewController: NSViewController, NSWindowDelegate, NSToolbarItemValidation {

	@IBOutlet weak var controlBt: NSButton!
	@IBOutlet weak var statusLb: NSTextField!

	@IBOutlet weak var versionLb: NSTextField! {
		didSet {
			versionLb.stringValue = L10n.version
		}
	}


	private let bridgesConfDelegate = SharedUtils()


	override func viewDidLoad() {
		super.viewDidLoad()

		let nc = NotificationCenter.default

		nc.addObserver(self, selector: #selector(updateUi), name: .vpnStatusChanged, object: nil)
		nc.addObserver(self, selector: #selector(updateUi), name: .vpnProgress, object: nil)

		updateUi()
	}

	override func viewDidAppear() {
		super.viewDidAppear()

		view.window?.title = "Orbot"

		for item in view.window?.toolbar?.items ?? [] {
			switch item.itemIdentifier.rawValue {
			case "log":
				item.label = L10n.log

			case "refresh":
				item.label = L10n.newCircuits

			case "settings":
				item.label = L10n.settings

			case "auth-cookies":
				item.label = L10n.authCookies

			case "bridges":
				item.label = L10n.bridgeConf

			default:
				break
			}

			item.paletteLabel = item.label
		}
	}


	// MARK: NSWindowDelegate

	public func windowWillClose(_ notification: Notification) {
		NSApp.stopModal()
	}


	// MARK: NSToolbarItemValidation

	func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
		if item.itemIdentifier.rawValue == "refresh" {
			return VpnManager.shared.sessionStatus == .connected
		}

		return true
	}


	// MARK: Actions

	@IBAction func control(_ sender: Any) {
		SharedUtils.control(startOnly: false)
	}

	@IBAction func refresh(_ sender: Any) {
		let hud = MBProgressHUD.showAdded(to: view, animated: true)
		hud?.mode = MBProgressHUDModeDeterminate
		hud?.progress = 0
		hud?.labelText = L10n.newCircuits

		let showError = { (error: Error) in
			hud?.progress = 1
			hud?.labelText = L10n.error
			hud?.detailsLabelText = error.localizedDescription
			hud?.hide(true, afterDelay: 3)
		}

		VpnManager.shared.getCircuits { circuits, error in
			if let error = error {
				return showError(error)
			}

			hud?.progress = 0.5

			VpnManager.shared.closeCircuits(circuits) { success, error in
				if let error = error {
					return showError(error)
				}

				hud?.progress = 1

				hud?.hide(true, afterDelay: 0.5)
			}
		}
	}

	@IBAction func bridgeConfiguration(_ sender: Any) {
		let vc = BridgesConfViewController()
		vc.transport = bridgesConfDelegate.transport
		vc.customBridges = bridgesConfDelegate.customBridges
		vc.delegate = bridgesConfDelegate

		let window = NSWindow(contentViewController: vc)
		window.delegate = self

		NSApp.runModal(for: window)

		window.close()
	}


	// MARK: Observers

	@objc func updateUi(_ notification: Notification? = nil) {

		// Trigger refresh button revalidation.
		NSApp.setWindowsNeedUpdate(true)

		let (statusIcon, buttonTitle, statusText) = SharedUtils.updateUi(notification)

		statusText.setAlignment(.center, range: NSRange(location: 0, length: statusText.length))

		controlBt.image = NSImage(named: statusIcon)
		controlBt.setTitle(buttonTitle)
		statusLb.attributedStringValue = statusText
	}
}

//
//  MainViewController.swift
//  Orbot Mac
//
//  Created by Benjamin Erhart on 11.08.22.
//  Copyright © 2020 - 2026 Guardian Project. All rights reserved.
//

import Cocoa
import IPtProxyUI
import NetworkExtension

class MainViewController: NSViewController, NSWindowDelegate, NSToolbarItemValidation {

	@IBOutlet weak var statusIcon: NSImageView! {
		didSet {
			statusIcon.cell?.setAccessibilityElement(false)
		}
	}

	@IBOutlet weak var shadowImg: NSImageView! {
		didSet {
			shadowImg.cell?.setAccessibilityElement(false)
		}
	}

	@IBOutlet weak var statusLb: NSTextField!
	@IBOutlet weak var statusSubLb: NSTextField!
	@IBOutlet weak var controlBt: NSButton! {
		didSet {
			controlBt.isBordered = false
			controlBt.wantsLayer = true
			controlBt.layer?.backgroundColor = NSColor.accent.cgColor
			controlBt.layer?.cornerRadius = 5
		}
	}

	@IBOutlet weak var smartConnectSw: NSButton! {
		didSet {
			smartConnectSw.setAttributedTitle(NSAttributedString(
				string: L10n.runSmartConnectToFindTheBestWay,
				attributes: [.foregroundColor: NSColor.white]))
		}
	}

	@IBOutlet weak var configureBt: NSButton! {
		didSet {
			configureBt.setTitle(L10n.chooseHowToConnect)
			configureBt.setAccessibilityIdentifier("bridge_configuration")
		}
	}


	private let bridgesConfDelegate = SharedUtils()


	override func viewDidLoad() {
		super.viewDidLoad()

		let callback: (Notification) -> Void = { [weak self] notification in
			self?.updateUi(notification)
		}

		let nc = NotificationCenter.default
		nc.addObserver(forName: .vpnStatusChanged, object: nil, queue: .main, using: callback)
		nc.addObserver(forName: .vpnProgress, object: nil, queue: .main, using: callback)

		updateUi()
	}

	override func viewDidAppear() {
		super.viewDidAppear()

		view.window?.title = Bundle.main.displayName

		for item in view.window?.toolbar?.items ?? [] {
			switch item.itemIdentifier.rawValue {
			case "kindness-mode":
				item.label = L10n.kindnessMode

			case "log":
				item.label = L10n.log

			case "refresh":
				item.label = L10n.newCircuits

			case "settings":
				item.label = L10n.settings

			case "auth-cookies":
				item.label = L10n.authCookies

			case "bridges":
				item.label = IPtProxyUI.L10n.bridgeConfiguration

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
			return VpnManager.shared.status == .connected
		}

		return true
	}


	// MARK: Actions

	@IBAction func control(_ sender: Any) {
		SharedUtils.control()
	}

	@IBAction func toggleSmartConnect(_ sender: NSView) {
		guard smartConnectSw.isEnabled else {
			return
		}

		if sender != smartConnectSw {
			smartConnectSw.state = smartConnectSw.state == .on ? .off : .on
		}

		Settings.smartConnect = smartConnectSw.state == .on

		updateUi()
	}

	@IBAction func refresh(_ sender: Any) {
		let hud = MBProgressHUD.showAdded(to: view, animated: true)
		hud?.mode = MBProgressHUDModeDeterminate
		hud?.progress = 0
		hud?.labelText = L10n.newCircuits

		let showError = { (error: Error) in
			hud?.progress = 1
			hud?.labelText = IPtProxyUI.L10n.error
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
		window.styleMask.remove(.miniaturizable)

		NSApp.runModal(for: window)

		window.close()
	}


	// MARK: Observers

	@objc func updateUi(_ notification: Notification? = nil) {

		// Trigger refresh button revalidation.
		NSApp.setWindowsNeedUpdate(true)

		let (statusIconName, showShadow, buttonTitle, statusText, statusSubtext, showConfButton) = SharedUtils.updateUi(
			notification, buttonFontSize: controlBt.font?.pointSize)

#if DEBUG
		animateOrbie = statusIconName == .imgOrbieStarting
#endif

		statusText.setAlignment(.center, range: NSRange(location: 0, length: statusText.length))

		statusIcon.image = NSImage(named: statusIconName)
		shadowImg.isHidden = !showShadow
		statusLb.attributedStringValue = statusText

		if let window = NSApp.mainWindow {
			NSAccessibility.post(
				element: window,
				notification: .announcementRequested,
				userInfo: [.announcement: statusText.string,
						   .priority: NSAccessibilityPriorityLevel.high.rawValue])
		}

		statusSubLb.stringValue = statusSubtext
		controlBt.setAttributedTitle(buttonTitle)

		smartConnectSw.state = Settings.smartConnect ? .on : .off
		smartConnectSw.isEnabled = VpnManager.shared.status == .disconnected
		smartConnectSw.isHidden = !showConfButton

		configureBt.isHidden = !showConfButton
	}


	// MARK: Private Methods

#if DEBUG
	private var animateOrbie = false {
		didSet {
			if animateOrbie && !oldValue {
				animateOrbie()
			}
		}
	}

	/**
	 This sort-of works, but the animation is not stable, so we don't use this in production.
	 */
	private func animateOrbie(up: Bool = true) {
		guard animateOrbie || !up else {
			statusIcon.needsLayout = true
			shadowImg.needsLayout = true

			return
		}

		// Make Orbie jump.
		let b1o = statusIcon.bounds
		let b1t = NSMakeRect(0, up ? -32 : 0, b1o.width, b1o.height)

		// Let the shadow follow along.
		let f2o = self.shadowImg.frame
		let r = up ? 0.75 : 1
		let w = f2o.width / r
		let h = f2o.height / r
		let x = (f2o.width - w) / 2
		let y = (f2o.height - h) / 2
		let b2t = NSMakeRect(x, y, w, h)

		NSAnimationContext.runAnimationGroup({ [weak self] context in
			guard let self = self else {
				return
			}

			context.duration = 0.5
			context.timingFunction = up ? .init(name: .easeOut) : .init(name: .easeIn)

			self.statusIcon.animator().bounds = b1t
			self.shadowImg.animator().bounds = b2t
		})
		{ [weak self] in
			self?.animateOrbie(up: !up)
		}
	}
#endif
}

//
//  TestingViewController.swift
//  Orbot Mac
//
//  Created by Benjamin Erhart on 20.04.26.
//  Copyright © 2026 Guardian Project. All rights reserved.
//

import Cocoa
import IPtProxyUI

class TestingViewController: NSViewController, NSWindowDelegate {

	protocol Delegate: AnyObject {

		func finished(success: Bool)
	}


	weak var delegate: Delegate?

	private var testStarted = false

	private var originalTransport: Transport = .none
	private var originalSmartConnect = false

	private var testSucceeded = false

	private var lastStatus: VpnManager.Status?

	@IBOutlet weak var testingContainer: NSView! {
		didSet {
			testingContainer.isHidden = false
		}
	}

	@IBOutlet weak var progress: NSProgressIndicator!

	@IBOutlet weak var explanationLb: NSTextField! {
		didSet {
			explanationLb.stringValue = L10n.beforeYouBecomeaSnowflakeProxy
		}
	}

	@IBOutlet weak var successContainer: NSView! {
		didSet {
			successContainer.isHidden = true
		}
	}

	@IBOutlet weak var successTitleLb: NSTextField! {
		didSet {
			successTitleLb.stringValue = L10n.approved
		}
	}

	@IBOutlet weak var successDescriptionLb: NSTextField! {
		didSet {
			successDescriptionLb.stringValue = L10n.youAreaGreatCandidate
		}
	}

	@IBOutlet weak var failContainer: NSView! {
		didSet {
			failContainer.isHidden = true
		}
	}

	@IBOutlet weak var failTitleLb: NSTextField! {
		didSet {
			failTitleLb.stringValue = L10n.notApproved
		}
	}

	@IBOutlet weak var failDescriptionLb: NSTextField! {
		didSet {
			failDescriptionLb.stringValue = L10n.youCannotBeaUsefulSnowflakeProxy
		}
	}

	@IBOutlet weak var failWarningLb: NSTextField! {
		didSet {
			failWarningLb.stringValue = L10n.doNotUseKindnessMode
		}
	}

	@IBOutlet weak var mainBt: NSButton! {
		didSet {
			mainBt.setTitle(L10n.cancel)
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		NotificationCenter.default.addObserver(self, selector: #selector(statusChanged), name: .vpnStatusChanged, object: nil)

		originalTransport = Settings.transport
		Settings.transport = .none

		originalSmartConnect = Settings.smartConnect
		Settings.smartConnect = false

		progress.startAnimation(nil)

		statusChanged()
	}

	override func viewDidAppear() {
		super.viewDidAppear()

		view.window?.title = L10n.testingQuality
	}


	@IBAction
	func dismiss(_ sender: NSButton) {
		Settings.transport = originalTransport
		Settings.smartConnect = originalSmartConnect

		delegate?.finished(success: testSucceeded)

		NSApp.stopModal()
	}

	@objc
	private func statusChanged() {
		print("Status: \(VpnManager.shared.status)")

		if lastStatus == VpnManager.shared.status {
			return
		}

		lastStatus = VpnManager.shared.status

		switch VpnManager.shared.status {
		case .notInstalled:
			VpnManager.shared.install()

		case .disabled:
			VpnManager.shared.enable()

		case .disconnected:
			if testStarted {
				// Nos! Not working.
				Task { @MainActor in
					testingContainer.isHidden = true
					progress.stopAnimation(nil)
					successContainer.isHidden = true
					failContainer.isHidden = false
				}
			}
			else {
				testStarted = true
				VpnManager.shared.connect()
			}

		case .evaluating, .connecting, .reasserting:
			// Ignore. Waiting for `connected`.
			break

		case .connected:
			// Yay! Success!
			Task { @MainActor in
				testingContainer.isHidden = true
				progress.stopAnimation(nil)
				successContainer.isHidden = false
				failContainer.isHidden = true
				mainBt.setTitle(NSLocalizedString("Continue", comment: ""))
			}

			testSucceeded = true

			NotificationCenter.default.removeObserver(self, name: .vpnStatusChanged, object: nil)

			VpnManager.shared.disconnect(explicit: true)

		case .disconnecting:
			// Ignore. Waiting for `disconnected`.
			break

		default:
			// Nos! Not working.
			Task { @MainActor in
				testingContainer.isHidden = true
				progress.stopAnimation(nil)
				successContainer.isHidden = true
				failContainer.isHidden = false
			}
		}
	}
}

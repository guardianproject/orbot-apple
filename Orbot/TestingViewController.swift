//
//  TestingViewController.swift
//  Orbot
//
//  Created by Benjamin Erhart on 16.04.26.
//  Copyright © 2026 Guardian Project. All rights reserved.
//

import UIKit
import IPtProxyUI

class TestingViewController: UIViewController {

	protocol Delegate: AnyObject {

		func finished(success: Bool)
	}


	weak var delegate: Delegate?

	private var testStarted = false

	private var originalTransport: Transport = .none
	private var originalSmartConnect = false

	private var testSucceeded = false

	private var lastStatus: VpnManager.Status?

	@IBOutlet weak var testingContainer: UIView! {
		didSet {
			testingContainer.isHidden = false
		}
	}

	@IBOutlet weak var explanationLb: UILabel! {
		didSet {
			explanationLb.text = L10n.beforeYouBecomeaSnowflakeProxy
		}
	}

	@IBOutlet weak var successContainer: UIView! {
		didSet {
			successContainer.isHidden = true
		}
	}

	@IBOutlet weak var successTitleLb: UILabel! {
		didSet {
			successTitleLb.text = L10n.approved
		}
	}

	@IBOutlet weak var successDescriptionLb: UILabel! {
		didSet {
			successDescriptionLb.text = L10n.youAreaGreatCandidate
		}
	}

	@IBOutlet weak var failContainer: UIView! {
		didSet {
			failContainer.isHidden = true
		}
	}

	@IBOutlet weak var failTitleLb: UILabel! {
		didSet {
			failTitleLb.text = L10n.notApproved
		}
	}

	@IBOutlet weak var failDescriptionLb: UILabel! {
		didSet {
			failDescriptionLb.text = L10n.youCannotBeaUsefulSnowflakeProxy
		}
	}

	@IBOutlet weak var failWarningLb: UILabel! {
		didSet {
			failWarningLb.text = L10n.doNotUseKindnessMode
		}
	}

	@IBOutlet weak var mainBt: UIButton! {
		didSet {
			mainBt.setTitle(NSLocalizedString("Cancel", comment: ""))
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.title = NSLocalizedString("Testing Quality…", comment: "")

		NotificationCenter.default.addObserver(self, selector: #selector(statusChanged), name: .vpnStatusChanged, object: nil)

		originalTransport = Settings.transport
		Settings.transport = .none

		originalSmartConnect = Settings.smartConnect
		Settings.smartConnect = false

		statusChanged()
	}


	@IBAction
	func dismiss() {
		Settings.transport = originalTransport
		Settings.smartConnect = originalSmartConnect

		delegate?.finished(success: testSucceeded)

		dismiss(animated: true)
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
				testingContainer.isHidden = true
				successContainer.isHidden = true
				failContainer.isHidden = false
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
			testingContainer.isHidden = true
			successContainer.isHidden = false
			failContainer.isHidden = true
			mainBt.setTitle(NSLocalizedString("Continue", comment: ""))

			testSucceeded = true

			NotificationCenter.default.removeObserver(self, name: .vpnStatusChanged, object: nil)

			VpnManager.shared.disconnect(explicit: true)

		case .disconnecting:
			// Ignore. Waiting for `disconnected`.
			break

		default:
			// Nos! Not working.
			testingContainer.isHidden = true
			successContainer.isHidden = true
			failContainer.isHidden = false
		}
	}
}

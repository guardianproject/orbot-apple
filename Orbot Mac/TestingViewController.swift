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

	private var testSucceeded = false

	@IBOutlet weak var testingContainer: NSView! {
		didSet {
			testingContainer.isHidden = false
		}
	}

	@IBOutlet weak var testingTitleLb: NSTextField! {
		didSet {
			testingTitleLb.stringValue = L10n.testingConnection
		}
	}

	@IBOutlet weak var explanationLb: NSTextField! {
		didSet {
			explanationLb.stringValue = L10n.pleaseWaitWhileWeCheck
		}
	}

	@IBOutlet weak var progress: NSProgressIndicator!

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

	@IBOutlet weak var mainBt: NSButton! {
		didSet {
			mainBt.setTitle(L10n.stopTest)
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		progress.startAnimation(nil)

		Task {
			if await ProxyQualityTest().evaluate() {
				Task { @MainActor in
					testingContainer.isHidden = true
					progress.stopAnimation(nil)
					successContainer.isHidden = false
					failContainer.isHidden = true
					mainBt.setTitle(L10n.cont)
				}

				testSucceeded = true
			}
			else {
				Task { @MainActor in
					testingContainer.isHidden = true
					progress.stopAnimation(nil)
					successContainer.isHidden = true
					failContainer.isHidden = false
					mainBt.setTitle(IPtProxyUI.L10n.ok)
				}
			}
		}
	}

	override func viewDidAppear() {
		super.viewDidAppear()

		view.window?.title = L10n.activateKindnessMode
	}


	@IBAction
	func dismiss(_ sender: NSButton) {
		delegate?.finished(success: testSucceeded)

		NSApp.stopModal()
	}
}

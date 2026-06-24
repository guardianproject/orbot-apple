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


	private var testSucceeded = false


	@IBOutlet weak var testingContainer: UIView! {
		didSet {
			testingContainer.isHidden = false
		}
	}

	@IBOutlet weak var titleLb: UILabel! {
		didSet {
			titleLb.text = NSLocalizedString("Testing Connection", comment: "")
		}
	}

	@IBOutlet weak var explanationLb: UILabel! {
		didSet {
			explanationLb.text = L10n.pleaseWaitWhileWeCheck
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

	@IBOutlet weak var mainBt: UIButton! {
		didSet {
			mainBt.setTitle(NSLocalizedString("Stop Test", comment: ""))
		}
	}


	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.title = NSLocalizedString("Activate Kindness Mode", comment: "")

		Task {
			if await ProxyQualityTest().evaluate() {
				Task { @MainActor in
					testingContainer.isHidden = true
					successContainer.isHidden = false
					failContainer.isHidden = true
					mainBt.setTitle(NSLocalizedString("Continue", comment: ""))

					testSucceeded = true
				}
			}
			else {
				Task { @MainActor in
					testingContainer.isHidden = true
					successContainer.isHidden = true
					failContainer.isHidden = false
					mainBt.setTitle(IPtProxyUI.L10n.ok)
				}
			}
		}
	}


	@IBAction
	func dismiss() {
		delegate?.finished(success: testSucceeded)

		dismiss(animated: true)
	}
}

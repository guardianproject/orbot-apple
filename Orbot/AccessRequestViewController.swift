//
//  AccessRequestViewController.swift
//  Orbot
//
//  Created by Benjamin Erhart on 23.02.23.
//  Copyright © 2020 - 2026 Guardian Project. All rights reserved.
//

import UIKit

class AccessRequestViewController: UIViewController {

	var token: ApiToken?

	var appName: String {
		token?.appName ?? token?.appId ?? "<unknown>"
	}

	var completion: ((_ granted: Bool) -> Void)?

	@IBOutlet weak var subtitleLb: UILabel! {
		didSet {
			let text = NSMutableAttributedString(string: String(
				format: NSLocalizedString("%1$@ wants to access %2$@.", comment: ""),
				appName,
				Bundle.main.displayName))

			text.color(substring: appName, with: .accent)

			subtitleLb.attributedText = text
		}
	}

	@IBOutlet weak var desc1Lb: UILabel! {
		didSet {
			let text = NSMutableAttributedString(string: String(
				format: NSLocalizedString("This will allow %1$@ to:", comment: ""),
				appName))

			text.color(substring: appName, with: .accent)

			desc1Lb.attributedText = text
		}
	}

	@IBOutlet weak var desc2Lb: UILabel! {
		didSet {
			desc2Lb.text = String(
				format: NSLocalizedString("%1$@ Get updates on the status of the connection.", comment: ""),
				"\u{2022}")
		}
	}

	@IBOutlet weak var desc3Lb: UILabel! {
		didSet {
			desc3Lb.text = String(
				format: NSLocalizedString("%1$@ Get information about Tor circuits.", comment: ""),
				"\u{2022}")
		}
	}

	@IBOutlet weak var desc4Lb: UILabel! {
		didSet {
			desc4Lb.text = String(
				format: NSLocalizedString("%1$@ Stop Tor.", comment: ""),
				"\u{2022}")
		}
	}

	@IBOutlet weak var desc5Lb: UILabel! {
		didSet {
			if token?.bypass ?? false {
				desc5Lb.text = String(
					format: NSLocalizedString("%1$@ Bypass %2$@", comment: ""),
					"\u{2022}",
					Bundle.main.displayName)
			}
			else {
				desc5Lb.isHidden = true
				desc5Lb.heightAnchor.constraint(equalToConstant: 0).isActive = true
			}
		}
	}

	@IBOutlet weak var grantBt: UIButton! {
		didSet {
			grantBt.setAttributedTitle(NSAttributedString(
				string: NSLocalizedString("Grant", comment: ""),
				attributes: [.foregroundColor: UIColor.label]))
		}
	}

	@IBOutlet weak var denyBt: UIButton! {
		didSet {
			denyBt.setAttributedTitle(NSAttributedString(
				string: NSLocalizedString("Deny", comment: ""),
				attributes: [.foregroundColor: UIColor.label]))
		}
	}

	override var isModalInPresentation: Bool {
		get {
			true
		}
		set {
			// Ignored.
		}
	}


	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.title = NSLocalizedString("Access Request", comment: "")
		navigationItem.rightBarButtonItem = .init(barButtonSystemItem: .close, target: self, action: #selector(deny))
	}

	@IBAction func grant() {
		completion?(true)
	}


	@IBAction func deny() {
		completion?(false)
	}
}

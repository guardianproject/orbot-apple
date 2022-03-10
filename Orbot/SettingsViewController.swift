//
//  SettingsViewController.swift
//  Orbot
//
//  Created by Benjamin Erhart on 08.03.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import UIKit
import Eureka

class SettingsViewController: FormViewController {

	private let explanation = NSLocalizedString("Comma-separated lists of:", comment: "") + "\n"
		+ String(format: NSLocalizedString("%1$@ node fingerprints, e.g. \"%2$@\"", comment: ""), "\u{2022}", "ABCD1234CDEF5678ABCD1234CDEF5678ABCD1234") + "\n"
		+ String(format: NSLocalizedString("%1$@ 2-letter country codes in braces, e.g. \"%2$@\"", comment: ""), "\u{2022}", "{cc}") + "\n"
		+ String(format: NSLocalizedString("%1$@ IP address patterns, e.g. \"%2$@\"", comment: ""), "\u{2022}", "255.254.0.0/8") + "\n"
		+ "\n"
		+ NSLocalizedString("Will take effect on restart.", comment: "")

	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.title = NSLocalizedString("Settings", comment: "")

		let closeBt = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(close))
		closeBt.accessibilityIdentifier = "close_settings"

		navigationItem.leftBarButtonItem = closeBt

		form
		+++ Section(NSLocalizedString("Node Configuration", comment: ""))

		<<< LabelRow() {
			$0.title = NSLocalizedString("Entry Nodes", comment: "")
			$0.value = NSLocalizedString("Only use these nodes as first hop. Ignored, when bridging is used.", comment: "")
			$0.cellStyle = .subtitle
			$0.cell.detailTextLabel?.numberOfLines = 0
		}

		<<< TextAreaRow() {
			$0.value = Settings.entryNodes
		}
		.onChange({ row in
			Settings.entryNodes = row.value
		})

		+++ LabelRow() {
			$0.title = NSLocalizedString("Exit Nodes", comment: "")
			$0.value = NSLocalizedString("Only use these nodes to connect outside the Tor network. You will degrade functionality if you list too few!", comment: "")
			$0.cellStyle = .subtitle
			$0.cell.detailTextLabel?.numberOfLines = 0
		}

		<<< TextAreaRow() {
			$0.value = Settings.exitNodes
		}
		.onChange({ row in
			Settings.exitNodes = row.value
		})

		+++ Section(footer: explanation)

		<<< LabelRow() {
			$0.title = NSLocalizedString("Exclude Nodes", comment: "")
			$0.value = NSLocalizedString("Do not use these nodes. Overrides entry and exit node list. May still be used for management purposes.", comment: "")
			$0.cellStyle = .subtitle
			$0.cell.detailTextLabel?.numberOfLines = 0
		}

		<<< TextAreaRow() {
			$0.value = Settings.excludeNodes
		}
		.onChange({ row in
			Settings.excludeNodes = row.value
		})

		<<< SwitchRow() {
			$0.title = NSLocalizedString("Also don't use excluded nodes for network management", comment: "")
			$0.cell.textLabel?.numberOfLines = 0

			$0.cell.textLabel?.font = UIFont.systemFont(ofSize: UIFont.systemFontSize)
		}
		.onChange({ row in
			if let value = row.value {
				Settings.strictNodes = value
			}
		})
	}

	// MARK: Actions

	@objc func close() {
		navigationController?.dismiss(animated: true)
	}
}

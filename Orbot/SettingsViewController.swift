//
//  SettingsViewController.swift
//  Orbot
//
//  Created by Benjamin Erhart on 08.03.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import UIKit
import Eureka
import IPtProxyUI

class SettingsViewController: BaseFormViewController {

	private let explanation1 = NSLocalizedString("Comma-separated lists of:", comment: "") + "\n"
		+ String(format: NSLocalizedString("%1$@ node fingerprints, e.g. \"%2$@\"", comment: ""), "\u{2022}", "ABCD1234CDEF5678ABCD1234CDEF5678ABCD1234") + "\n"
		+ String(format: NSLocalizedString("%1$@ 2-letter country codes in braces, e.g. \"%2$@\"", comment: ""), "\u{2022}", "{cc}") + "\n"
		+ String(format: NSLocalizedString("%1$@ IP address patterns, e.g. \"%2$@\"", comment: ""), "\u{2022}", "255.254.0.0/8") + "\n"

	private let explanation2 = String(format: NSLocalizedString("%1$@ Options need 2 leading minuses: %2$@", comment: ""), "\u{2022}", "--Option") + "\n"
		+ String(format: NSLocalizedString("%@ Arguments to an option need to be in a new line.", comment: ""), "\u{2022}") + "\n"
		+ String(format: NSLocalizedString("%1$@ Some options might get overwritten by %2$@.", comment: ""), "\u{2022}", Bundle.main.displayName)


	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.title = NSLocalizedString("Settings", comment: "")

		closeBt.accessibilityIdentifier = "close_settings"

		form
		+++ LabelRow() {
			$0.value = NSLocalizedString("Settings will only take effect after restart.", comment: "")
			$0.cellStyle = .subtitle
			$0.cell.detailTextLabel?.numberOfLines = 0
		}

		+++ Section(header: NSLocalizedString("Onion-only Mode", comment: ""), footer: NSLocalizedString("ATTENTION: This may harm your anonymity and security!", comment: ""))
		<<< SwitchRow() {
			$0.title = String(format: NSLocalizedString("Disable %@ for non-onion traffic", comment: ""), Bundle.main.displayName)
			$0.value = Settings.onionOnly
			$0.cell.textLabel?.numberOfLines = 0
		}
		.onChange { row in
			if row.value ?? false {
				let message = NSLocalizedString("ATTENTION: This may harm your anonymity and security!", comment: "")
				+ "\n\n"
				+ NSLocalizedString("Only traffic to onion services (to domains ending in \".onion\") will be routed over Tor.", comment: "")
				+ "\n\n"
				+ NSLocalizedString("Traffic to all other domains will be routed through your normal Internet connection.", comment: "")
				+ "\n\n"
				+ NSLocalizedString("If these onion services aren't configured correctly, you will leak information to your Internet Service Provider and anybody else listening on that traffic!", comment: "")

				AlertHelper.present(
					self,
					message: message,
					title: NSLocalizedString("Warning", comment: ""),
					actions: [AlertHelper.cancelAction(handler: { _ in
						row.value = false
						row.updateCell()
					}),
							  AlertHelper.destructiveAction(NSLocalizedString("Activate", comment: ""), handler: { _ in
								  Settings.onionOnly = true
							  })])
			}
			else {
				if Settings.onionOnly {
					Settings.onionOnly = false
					VpnManager.shared.disconnect()
				}
			}
		}

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

		+++ Section(footer: explanation1)

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

		+++ Section(NSLocalizedString("Advanced Tor Configuration", comment: ""))

		<<< ButtonRow() {
			$0.title = NSLocalizedString("Tor Configuration Reference", comment: "")
		}
		.onCellSelection({ cell, row in
			UIApplication.shared.open(URL(string: "https://2019.www.torproject.org/docs/tor-manual.html")!)
		})

		+++ MultivaluedSection(multivaluedOptions: [.Insert, .Delete], footer: explanation2) {
			$0.addButtonProvider = { _ in
				return ButtonRow()
			}

			$0.multivaluedRowToInsertAt = { index in
				return TextRow() {
					$0.tag = "advanced_\(index)"
					$0.turnOffAutoCorrect()
					$0.placeholder = index % 2 == 0
						? "--ReachableAddresses"
						: "99.0.0.0/8, reject 18.0.0.0/8, accept *:80"
				}
				.onChange { [weak self] _ in
					self?.saveAdvancedConf()
				}
			}

			if let conf = Settings.advancedTorConf, !conf.isEmpty {
				for i in 0 ..< conf.count {
					let r = $0.multivaluedRowToInsertAt!(i)
					r.baseValue = conf[i]
					$0 <<< r
				}
			}
			else {
				$0 <<< $0.multivaluedRowToInsertAt!(0)
				$0 <<< $0.multivaluedRowToInsertAt!(1)
			}
		}
	}


	// MARK: UITableViewDataSource

	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		super.tableView(tableView, commit: editingStyle, forRowAt: indexPath)

		guard editingStyle == .delete else {
			return
		}

		saveAdvancedConf()
	}


	// MARK: Private Methods

	private func saveAdvancedConf() {
		Settings.advancedTorConf = form.allRows
			.filter { $0.tag?.starts(with: "advanced_") ?? false }
			.sorted { Int($0.tag![9...])! < Int($1.tag![9...])! }
			.compactMap { $0.baseValue as? String }
	}
}

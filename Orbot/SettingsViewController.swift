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

	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.title = L10n.settings

		closeBt.accessibilityIdentifier = "close_settings"

		form
		+++ Section()
		<<< SwitchRow() {
			$0.title = L10n.automaticallyRestartOnError
			$0.value = Settings.restartOnError
			$0.cell.textLabel?.numberOfLines = 0
		}
		.onChange { row in
			Settings.restartOnError = row.value ?? false

			VpnManager.shared.updateRestartOnError()
		}

		<<< SwitchRow() {
			$0.title = L10n.switchBackToLastUsedVpnAfterStop
			$0.value = Settings.disableOnStop
			$0.cell.textLabel?.numberOfLines = 0
		}
		.onChange { row in
			Settings.disableOnStop = row.value ?? false
		}

		+++ Section(header: L10n.onionOnlyMode, footer: L10n.attentionAnonymity)
		<<< SwitchRow("onionOnlyMode") {
			$0.title = L10n.disableForNonOnionTraffic
			$0.value = Settings.onionOnly
			$0.cell.textLabel?.numberOfLines = 0
		}
		.onChange { row in
			if row.value ?? false {
				AlertHelper.present(
					self,
					message: L10n.settingsExplanation3,
					title: L10n.warning,
					actions: [
						AlertHelper.cancelAction(handler: { _ in
							row.value = false
							row.updateCell()
						}),
						AlertHelper.destructiveAction(L10n.activate, handler: { _ in
							Settings.onionOnly = true
						})])
			}
			else {
				if Settings.onionOnly {
					Settings.onionOnly = false
					VpnManager.shared.disconnect(explicit: true)
				}
			}
		}

		+++ Section(L10n.nodeConfiguration)

		<<< LabelRow() {
			$0.title = L10n.entryNodes
			$0.value = L10n.entryNodesExplanation
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
			$0.title = L10n.exitNodes
			$0.value = L10n.exitNodesExplanation
			$0.cellStyle = .subtitle
			$0.cell.detailTextLabel?.numberOfLines = 0
		}

		<<< TextAreaRow() {
			$0.value = Settings.exitNodes
		}
		.onChange({ row in
			Settings.exitNodes = row.value
		})

		+++ Section(footer: L10n.settingsExplanation1)

		<<< LabelRow() {
			$0.title = L10n.excludeNodes
			$0.value = L10n.excludeNodesExplanation
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
			$0.title = L10n.excludeNodesNever
			$0.cell.textLabel?.numberOfLines = 0

			$0.cell.textLabel?.font = UIFont.systemFont(ofSize: UIFont.systemFontSize)

			$0.value = Settings.strictNodes
		}
		.onChange({ row in
			if let value = row.value {
				Settings.strictNodes = value
			}
		})

		+++ Section(L10n.advancedTorConf)

		<<< ButtonRow() {
			$0.title = L10n.torConfReference
		}
		.onCellSelection({ cell, row in
			UIApplication.shared.open(SharedUtils.torConfUrl)
		})

		+++ MultivaluedSection(multivaluedOptions: [.Insert, .Delete], footer: L10n.settingsExplanation2) {
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

		+++ Section(L10n.expert)
		<<< IntRow() {
			$0.title = L10n.smartConnectTimeout
			$0.value = Int(Settings.smartConnectTimeout)
		}
		.onChange({ row in
			if let value = row.value {
				Settings.smartConnectTimeout = Double(value)
			}
		})

		+++ Section(L10n.maintenance)
		<<< ButtonRow("clearCache") {
			$0.title = L10n.clearTorCache
			$0.disabled = Condition.function(["clearCache"], { _ in
				VpnManager.shared.isConnected
			})
		}
		.onCellSelection({ _, row in
			if row.isDisabled {
				return
			}

			TorHelpers.clearCache()

			AlertHelper.present(self, message: L10n.cleared, title: L10n.clearTorCache)
		})
		<<< SwitchRow() {
			$0.title = NSLocalizedString("Always clear cache before start", comment: "")
			$0.value = Settings.alwaysClearCache
			$0.cell.textLabel?.numberOfLines = 0
		}
		.onChange { row in
			Settings.alwaysClearCache = row.value ?? false
		}

		<<< LabelRow() {
			$0.title = L10n.version
			$0.cellStyle = .default

			if let textLabel = $0.cell.textLabel {
				textLabel.textAlignment = .center

				textLabel.font = textLabel.font.withSize(textLabel.font.pointSize * 0.75)
			}
		}

		NotificationCenter.default.addObserver(forName: .vpnStatusChanged, object: nil, queue: .main) { [weak self] _ in
			self?.form.rowBy(tag: "clearCache")?.evaluateDisabled()
		}
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

		VpnManager.shared.configChanged()
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

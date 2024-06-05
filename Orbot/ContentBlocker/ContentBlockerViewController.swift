//
//  ContentBlockerViewController.swift
//  Orbot
//
//  Created by Benjamin Erhart on 11.04.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import UIKit
import Eureka
import IPtProxyUI
import SafariServices

class ContentBlockerViewController: BaseFormViewController, BlockerViewControllerDelegate {

	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.title = NSLocalizedString("Content Blocker", comment: "")

		form
		+++ LabelRow {
			$0.value = NSLocalizedString(
				"A \"Content Blocker\" provides a list of things to block in Safari, all other browsers and all web views used in apps.",
				comment: "") + "\n\n"
			+ NSLocalizedString(
				"Create your own rules here to e.g. block popups or third-party scripts.",
				comment: "") + "\n\n"
			+ NSLocalizedString(
				"To make it work, you will need to activate the blocker:",
				comment: "") + "\n"
			+ NSLocalizedString("Go to iOS Settings App -> Safari -> Extensions.", comment: "")

			$0.cellStyle = .subtitle
			$0.cell.detailTextLabel?.numberOfLines = 0
		}

		+++ MultivaluedSection(multivaluedOptions: [.Reorder, .Insert, .Delete]) { [weak self] in
			$0.addButtonProvider = { _ in
				return ButtonRow()
			}

			$0.multivaluedRowToInsertAt = { index in
				return ButtonRow() {
					if index >= BlockList.shared.count {
						BlockList.shared.append(
							BlockItem(trigger: BlockTrigger(urlFilter: ".*", resourceType: [.popup]),
									  action: BlockAction(type: .block)))

						self?.open(index)
					}

					$0.cell.textLabel?.numberOfLines = 0

					let font = $0.cell.textLabel?.font ?? UIFont.systemFont(ofSize: UIFont.buttonFontSize)
					$0.cell.textLabel?.font = UIFont(name: font.familyName, size: font.pointSize - 3)
				}
				.cellUpdate({ cell, row in
					let item: BlockItem?

					if let index = row.indexPath?.row, index < BlockList.shared.count {
						item = BlockList.shared[index]
					}
					else {
						item = nil
					}

					row.title = item?.description

					cell.textLabel?.textAlignment = .natural
				})
				.onCellSelection { cell, row in
					let index = Int(string: row.tag ?? "0") ?? 0

					self?.open(index)
				}
			}

			for i in 0 ..< BlockList.shared.count {
				$0 <<< $0.multivaluedRowToInsertAt!(i)
			}
		}

		SFContentBlockerManager.getStateOfContentBlocker(withIdentifier: Config.contentBlockerBundleId) { [weak self] state, error in
			let value: String

			if let error = error {
				value = error.localizedDescription
			}
			else {
				value = (state?.isEnabled ?? false)
					? NSLocalizedString("enabled", comment: "")
					: NSLocalizedString("disabled", comment: "")
			}

			DispatchQueue.main.async {
				self?.form.first?.append(LabelRow("state") {
					$0.title = NSLocalizedString("Current State", comment: "")
					$0.value = value
				})
			}
		}
	}


	// MARK: BlockerViewControllerDelegate

	func update(_ index: Int) {
		form.last?.allRows[index].updateCell()
	}


	// MARK: UITableViewDataSource

	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		super.tableView(tableView, commit: editingStyle, forRowAt: indexPath)

		guard indexPath.section == 1 && editingStyle == .delete else {
			return
		}

		BlockList.shared.remove(at: indexPath.row)

		write()
	}

	override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		super.tableView(tableView, moveRowAt: sourceIndexPath, to: destinationIndexPath)

		guard sourceIndexPath.section == 1 && destinationIndexPath.section == 1 else {
			return
		}

		let blocker = BlockList.shared.remove(at: sourceIndexPath.row)
		BlockList.shared.insert(blocker, at: destinationIndexPath.row)

		write()
	}


	// MARK: Private Methods

	private func open(_ index: Int) {
		DispatchQueue.main.async {
			let vc = BlockerViewController(index: index)
			vc.delegate = self

			self.navigationController?.pushViewController(vc, animated: true)
		}
	}

	private func write() {
		do {
			try BlockList.shared.write()
		}
		catch {
			AlertHelper.present(self, message: error.localizedDescription)
		}
	}
}

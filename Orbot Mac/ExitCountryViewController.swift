//
//  ExitCountryViewController.swift
//  Orbot Mac
//
//  Created by Benjamin Erhart on 29.12.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import Cocoa

extension Notification.Name {
	static let exitNodesChanged = Notification.Name("exit-nodes-changed")
	static let exitCountrySelectorClosed = Notification.Name("exit-country-selector-closed")
}


class ExitCountryViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

	private var countries = ExitNodeCountries.shared.getCountries()

	private var isInit = true

	@IBOutlet weak var tableView: NSTableView!

	override func viewDidLoad() {
		super.viewDidLoad()

		tableView.tableColumns.first?.headerCell.stringValue = L10n.exitNodeCountries
	}

	override func viewWillAppear() {
		super.viewWillAppear()

		countries = ExitNodeCountries.shared.getCountries()

		var indexes = IndexSet()
		var row = 0

		for country in countries {
			if country.inUse {
				Logger.log(country.code)

				indexes.insert(row)
			}

			row += 1
		}

		isInit = true

		tableView.selectRowIndexes(indexes, byExtendingSelection: false)

		isInit = false
	}

	override func viewDidDisappear() {
		super.viewDidDisappear()

		NotificationCenter.default.post(name: .exitCountrySelectorClosed, object: nil)
	}

	func numberOfRows(in tableView: NSTableView) -> Int {
		countries.count
	}

	func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
		let country = countries[row]

		return "\(country.flag) \(country.localizedName)"
	}

	func tableView(_ tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
		if isInit {
			return proposedSelectionIndexes
		}

		ExitNodeCountries.shared.removeAll()

		for row in proposedSelectionIndexes {
			ExitNodeCountries.shared.add(code: countries[row].code)
		}

		NotificationCenter.default.post(name: .exitNodesChanged, object: nil)

		return proposedSelectionIndexes
	}
}

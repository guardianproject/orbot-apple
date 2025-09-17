//
//  ChangeExitViewController.swift
//  Orbot
//
//  Created by Benjamin Erhart on 24.11.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import UIKit
import Eureka

class ChangeExitViewController: BaseFormViewController, UISearchResultsUpdating {

	private lazy var countries = ExitNodeCountries.shared.getCountries()

	private var filteredCountries: [ExitNodeCountries.Country]?

	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.title = L10n.exitNodeCountries

		navigationItem.rightBarButtonItem  = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(removeAll))


		let sc = UISearchController(searchResultsController: nil)
		sc.searchResultsUpdater = self
		sc.obscuresBackgroundDuringPresentation = false
		sc.searchBar.autocapitalizationType = .none

		navigationItem.searchController = sc

		let section = Section()

		for country in countries {
			section <<< CheckRow(country.code) {
				$0.title = "\(country.flag) \(country.localizedName)"
				$0.value = country.inUse
				$0.hidden = Condition.function([], { _ in
					self.filteredCountries != nil && !self.filteredCountries!.contains(country)
				})
			}
			.cellUpdate({ cell, row in
				cell.accessibilityLabel = country.localizedName
			})
			.onChange({ row in
				guard let code = row.tag else {
					return
				}

				if row.value ?? false {
					ExitNodeCountries.shared.add(code: code)
				}
				else {
					ExitNodeCountries.shared.remove(code: code)
				}
			})
		}

		form +++ section
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

		VpnManager.shared.configChanged()
	}


	// MARK: UISearchResultsUpdating

	func updateSearchResults(for searchController: UISearchController) {
		guard let search = searchController.searchBar.text?
			.trimmingCharacters(in: .whitespacesAndNewlines)
			.lowercased()
		else {
			return
		}

		filteredCountries = search.isEmpty ? nil
			: countries.filter({ $0.code == search || $0.localizedName.lowercased().contains(search) })

		form.allRows.forEach { $0.evaluateHidden() }
	}


	// MARK: Actions

	@objc func removeAll() {
		ExitNodeCountries.shared.removeAll()

		for row in form.allRows {
			(row as? CheckRow)?.value = false
			row.updateCell()
		}
	}
}

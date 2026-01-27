//
//  ExitNodeCountries.swift
//  Orbot
//
//  Created by Benjamin Erhart on 24.11.22.
//  Copyright © 2020 - 2026 Guardian Project. All rights reserved.
//

import Foundation
import IPtProxyUI

class ExitNodeCountries {

	class Country: IPtProxyUI.Country {

		fileprivate(set) var inUse = false
	}


	static let shared = ExitNodeCountries()

	private var countries: [Country]

	private var nodes: [String] {
		Settings.exitNodes?.split(separator: ",")
			.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
			?? []
	}


	private init() {
		if let url = Bundle.main.url(forResource: "exit-node-countries", withExtension: "plist"),
		   let data = try? Data(contentsOf: url),
		   let countries = try? PropertyListDecoder().decode([String].self, from: data)
		{
			self.countries = countries
				.map({ Country(code: $0) })
				.sorted()
		}
		else {
			countries = []
		}

		NotificationCenter.default.addObserver(forName: NSLocale.currentLocaleDidChangeNotification, object: nil, queue: nil) { _ in
			for country in self.countries {
				country.clearCache()
			}

			self.countries.sort()
		}
	}


	func getCountries() -> [Country] {
		let nodes = self.nodes.compactMap { extracted(code: $0) }

		for country in countries {
			country.inUse = nodes.contains(country.code)
		}

		return countries
	}

	func add(code: String) {
		let code = code.lowercased()

		workOnNodeList { nodes in
			if nodes.first(where: { extracted(code: $0) == code }) == nil {
				nodes.append("{\(code)}")
			}
		}
	}

	func remove(code: String) {
		let code = code.lowercased()

		workOnNodeList { nodes in
			nodes.removeAll { extracted(code: $0) == code }
		}
	}

	func removeAll() {
		workOnNodeList { nodes in
			nodes.removeAll { extracted(code: $0) != nil }
		}
	}

	private func workOnNodeList(callback: (_ nodes: inout [String]) -> Void) {
		var nodes = self.nodes
		let count = nodes.count

		callback(&nodes)

		if count != nodes.count {
			Settings.exitNodes = nodes.isEmpty ? nil : nodes.joined(separator: ",")
		}
	}

	private func extracted(code: String) -> String? {
		guard code.hasPrefix("{") && code.hasSuffix("}") else {
			return nil
		}

		var c = code
		c.removeFirst()
		c.removeLast()

		return c.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
	}
}

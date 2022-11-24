//
//  ExitNodeCountries.swift
//  Orbot
//
//  Created by Benjamin Erhart on 24.11.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import Foundation

class ExitNodeCountries {

	class Country: Equatable {

		static func == (lhs: ExitNodeCountries.Country, rhs: ExitNodeCountries.Country) -> Bool {
			lhs.code == rhs.code
		}

		let code: String

		fileprivate(set) var inUse = false

		private var _flag: String?
		var flag: String {
			if _flag == nil {

				let base: UInt32 = 127397
				_flag = ""

				for v in code.uppercased().unicodeScalars {
					_flag?.unicodeScalars.append(UnicodeScalar(base + v.value)!)
				}

			}

			return _flag!
		}

		fileprivate var _localizedName: String?
		var localizedName: String {
			if _localizedName == nil {
				_localizedName = Locale.current.localizedString(forRegionCode: code) ?? code
			}

			return _localizedName!
		}

		init(code: String) {
			self.code = code.lowercased()
		}
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
				.sorted { $0.localizedName.compare($1.localizedName) == .orderedAscending }
		}
		else {
			countries = []
		}

		NotificationCenter.default.addObserver(forName: NSLocale.currentLocaleDidChangeNotification, object: nil, queue: nil) { _ in
			for country in self.countries {
				country._localizedName = nil
			}

			self.countries.sort { $0.localizedName.compare($1.localizedName) == .orderedAscending }
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

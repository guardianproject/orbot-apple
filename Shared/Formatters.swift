//
//  Formatters.swift
//  Orbot
//
//  Created by Benjamin Erhart on 11.08.22.
//  Copyright © 2020 - 2026 Guardian Project. All rights reserved.
//

import Foundation

class Formatters {

	private static let pnf: NumberFormatter = {
		let nf = NumberFormatter()
		nf.numberStyle = .percent
		nf.maximumFractionDigits = 1

		return nf
	}()

	private static let nf: NumberFormatter = {
		let nf = NumberFormatter()
		nf.numberStyle = .decimal
		nf.maximumFractionDigits = 0

		return nf
	}()


	class func formatPercent(_ value: Float) -> String? {
		pnf.string(from: NSNumber(value: value))
	}

	class func format(_ value: Int) -> String {
		nf.string(from: NSNumber(value: value)) ?? String(value)
	}
}

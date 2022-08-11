//
//  Formatters.swift
//  Orbot
//
//  Created by Benjamin Erhart on 11.08.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import Foundation

class Formatters {

	private static let nf: NumberFormatter = {
		let nf = NumberFormatter()
		nf.numberStyle = .percent
		nf.maximumFractionDigits = 1

		return nf
	}()


	class func format(value: Float) -> String? {
		nf.string(from: NSNumber(value: value))
	}
}

//
//  String+Helpers.swift
//  Orbot
//
//  Created by Benjamin Erhart on 13.04.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import Foundation

extension String {

	static let imgOrbieOff = "orbie.off"
	static let imgOrbieStarting = "orbie.starting"
	static let imgOrbieOn = "orbie.on"
	static let imgOrbieOnionOnly = "orbie.onion-only"
	static let imgOrbieDead = "orbie.dead"
	static let imgOrbieCharging = "orbie.charging"


	var nilOnEmpty: String? {
		let text = trimmingCharacters(in: .whitespacesAndNewlines)

		// Transifex just doesn't show empty strings to the translators at all.
		// BartyCrouch also complains. Ugly. We'll se what translators will do...
		if text.isEmpty || text == "__empty__" {
			return nil
		}

		return self
	}

	subscript(value: Int) -> Character {
		self[index(startIndex, offsetBy: value)]
	}

	subscript(value: NSRange) -> Substring {
		self[value.lowerBound..<value.upperBound]
	}

	subscript(value: CountableClosedRange<Int>) -> Substring {
		self[index(startIndex, offsetBy: value.lowerBound)...index(startIndex, offsetBy: value.upperBound)]
	}

	subscript(value: CountableRange<Int>) -> Substring {
		self[index(startIndex, offsetBy: value.lowerBound)..<index(startIndex, offsetBy: value.upperBound)]
	}

	subscript(value: PartialRangeUpTo<Int>) -> Substring {
		self[..<index(startIndex, offsetBy: value.upperBound)]
	}

	subscript(value: PartialRangeThrough<Int>) -> Substring {
		self[...index(startIndex, offsetBy: value.upperBound)]
	}

	subscript(value: PartialRangeFrom<Int>) -> Substring {
		self[index(startIndex, offsetBy: value.lowerBound)...]
	}

	func nsRange(of aString: any StringProtocol) -> NSRange? {
		if let range = range(of: aString) {
			return NSRange(range, in: self)
		}

		return nil
	}
}

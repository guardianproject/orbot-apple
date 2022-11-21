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

	static let colorBlack1 = "Black1"
	static let colorBlack2 = "Black2"
	static let colorBlack3 = "Black3"

	static let colorAccent1 = "Accent1"
	static let colorAccent2 = "Accent2"


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
}

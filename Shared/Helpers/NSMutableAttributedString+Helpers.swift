//
//  NSMutableAttributedString+Helpers.swift
//  Orbot
//
//  Created by Benjamin Erhart on 23.02.23.
//  Copyright © 2023 Guardian Project. All rights reserved.
//

#if os(macOS)
import Cocoa
#else
import UIKit
#endif

extension NSMutableAttributedString {

	func color(substring: String, with color: Color) {
		if let range = string.range(of: substring) {
			self.color(range: range, with: color)
		}
	}

	func color(range: Range<String.Index>, with color: Color) {
		self.addAttribute(.foregroundColor, value: color, range: NSRange(range, in: string))
	}
}

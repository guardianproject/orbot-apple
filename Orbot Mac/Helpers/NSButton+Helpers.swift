//
//  NSButton+Helpers.swift
//  Orbot
//
//  Created by Benjamin Erhart on 11.08.22.
//  Copyright © 2020 - 2026 Guardian Project. All rights reserved.
//

import Cocoa

extension NSButton {

	func setTitle(_ title: String?) {
		self.title = title ?? ""
		alternateTitle = title ?? ""
	}

	func setAttributedTitle(_ title: NSAttributedString?) {
		attributedTitle = title ?? NSAttributedString(string: "")
		attributedAlternateTitle = title ?? NSAttributedString(string: "")
	}
}

class NonDimmingNSButtonCell: NSButtonCell {

	override func drawTitle(_ title: NSAttributedString, withFrame frame: NSRect, in controlView: NSView) -> NSRect {
		return super.drawTitle(isEnabled ? title : attributedTitle, withFrame: frame, in: controlView)
	}
}

//
//  IconView.swift
//  Orbot Mac
//
//  Created by Benjamin Erhart on 30.06.26.
//  Copyright © 2026 Guardian Project. All rights reserved.
//

import Cocoa

class IconView: NSImageView {

	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)

		setBackground()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)

		setBackground()
	}


	private func setBackground() {
		wantsLayer = true
		layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
		layer?.cornerRadius = frame.width / 2
	}
}

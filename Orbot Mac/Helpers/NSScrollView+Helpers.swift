//
//  NSScrollView+Helpers.swift
//  Orbot Mac
//
//  Created by Benjamin Erhart on 23.08.22.
//  Copyright © 2020 - 2026 Guardian Project. All rights reserved.
//

import Cocoa

extension NSScrollView {

	var isAtBottom: Bool {
		contentView.bounds.origin.y == 0
	}

	func scrollToBottom() {
		contentView.scroll(to: NSMakePoint(0, 0))
	}
}


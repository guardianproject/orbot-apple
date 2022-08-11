//
//  NSButton+Helpers.swift
//  Orbot
//
//  Created by Benjamin Erhart on 11.08.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import Cocoa

extension NSButton {

	func setTitle(_ title: String?) {
		self.title = title ?? ""
		alternateTitle = title ?? ""
	}
}

//
//  Color.swift
//  Orbot
//
//  Created by Benjamin Erhart on 27.02.23.
//  Copyright © 2023 Guardian Project. All rights reserved.
//

#if os(macOS)

import Cocoa

typealias Color = NSColor

extension NSColor {
	static let secondaryLabel = NSColor.secondaryLabelColor
}

#else

import UIKit

typealias Color = UIColor

#endif

extension Color {

	static let black1 = Color(named: "Black1")!
	static let black2 = Color(named: "Black2")!
	static let black3 = Color(named: "Black3")!

	static let accent1 = Color(named: "Accent1")!
	static let accent2 = Color(named: "Accent2")!

	static let brightGreen = Color(named: "BrightGreen")!
	static let darkGreen = Color(named: "DarkGreen")!
}

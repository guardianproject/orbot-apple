//
//  Color.swift
//  Orbot
//
//  Created by Benjamin Erhart on 27.02.23.
//  Copyright © 2020 - 2026 Guardian Project. All rights reserved.
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

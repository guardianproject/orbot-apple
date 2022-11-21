//
//  DebugMessage.swift
//  Orbot
//
//  Created by Benjamin Erhart on 17.11.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import Foundation

class DebugMessage: NSObject, Message {

	static var supportsSecureCoding = true

	override init() {
		super.init()
	}

	required init?(coder: NSCoder) {
		super.init()
	}

	func encode(with coder: NSCoder) {
	}
}

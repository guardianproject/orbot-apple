//
//  Message.swift
//  Orbot
//
//  Created by Benjamin Erhart on 20.05.20.
//  Copyright © 2020 - 2026 Guardian Project. All rights reserved.
//

import Foundation

class Message: NSObject, NSSecureCoding {

	class var supportsSecureCoding: Bool {
		true
	}

	override init() {
		super.init()
	}

	required init?(coder: NSCoder) {
		super.init()
	}


	func encode(with coder: NSCoder) {
	}
}

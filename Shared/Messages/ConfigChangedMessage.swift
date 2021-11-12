//
//  ConfigChangedMessage.swift
//  Orbot
//
//  Created by Benjamin Erhart on 09.11.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import UIKit

class ConfigChangedMessage: NSObject, Message {

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

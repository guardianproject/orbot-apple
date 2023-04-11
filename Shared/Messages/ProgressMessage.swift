//
//  ProgressMessage.swift
//  Orbot
//
//  Created by Benjamin Erhart on 20.05.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import Foundation

class ProgressMessage: Message {

	override class var supportsSecureCoding: Bool {
		true
	}

	let progress: Float

	init(_ progress: Float) {
		self.progress = progress

		super.init()
	}

	required init?(coder: NSCoder) {
		progress = coder.decodeFloat(forKey: "progress")

		super.init(coder: coder)
	}

	override func encode(with coder: NSCoder) {
		super.encode(with: coder)

		coder.encode(progress, forKey: "progress")
	}
}

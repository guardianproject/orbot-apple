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
	let summary: String?

	init(_ progress: Float, _ summary: String?) {
		self.progress = progress
		self.summary = summary

		super.init()
	}

	required init?(coder: NSCoder) {
		progress = coder.decodeFloat(forKey: "progress")
		summary = coder.decodeObject(forKey: "summary") as? String

		super.init(coder: coder)
	}

	override func encode(with coder: NSCoder) {
		super.encode(with: coder)

		coder.encode(progress, forKey: "progress")
		coder.encode(summary, forKey: "summary")
	}
}

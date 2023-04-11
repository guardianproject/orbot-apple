//
//  CloseCircuitsMessage.swift
//  Orbot
//
//  Created by Benjamin Erhart on 20.05.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import Foundation
import Tor

class CloseCircuitsMessage: Message {

	override class var supportsSecureCoding: Bool {
		true
	}

	let circuits: [TorCircuit]

	init(_ circuits: [TorCircuit]) {
		self.circuits = circuits

		super.init()
	}

	required init?(coder: NSCoder) {
		circuits = coder.decodeObject(of: [NSArray.self, TorCircuit.self],
									  forKey: "circuits") as? [TorCircuit] ?? []

		super.init(coder: coder)
	}

	override func encode(with coder: NSCoder) {
		super.encode(with: coder)

		coder.encode(circuits, forKey: "circuits")
	}
}

//
//  OnionmasqPTProvider.swift
//  Orbot
//
//  Created by Benjamin Erhart on 31.08.23.
//  Copyright © 2023 Guardian Project. All rights reserved.
//

import NetworkExtension

class OnionmasqPTProvider: BasePTProvider {

	override func startTun2Socks(socksAddr: String?, dnsAddr: String?) {
		// Ignored. Starts in TorManager.
	}

	override func stopTun2Socks() {
		// Ignored. Stops in TorManager.
	}
}

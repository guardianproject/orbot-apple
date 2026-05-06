//
//  ProxyQualityTest.swift
//  Orbot
//
//  Created by Benjamin Erhart on 06.05.26.
//  Copyright © 2026 Guardian Project. All rights reserved.
//

import Foundation
import IPtProxyUI

class ProxyQualityTest {

	private static let timeout: UInt64 = 90 // seconds
	private static let retries = 2

	private var lastStatus: VpnManager.Status?
	private var trialCounter = 0

	private let originalTransport: Transport
	private let originalSmartConnect: Bool

	private let stream = AsyncStream<Bool>.makeStream()


	init() {
		originalTransport = Settings.transport
		originalSmartConnect = Settings.smartConnect
	}

	/**
	 Run the test.

	 Can only be used once!

	 - returns: true, if successful, false if test fails.
	 */
	func evaluate() async -> Bool {
		if lastStatus != nil {
			return false // Can only be used once!
		}

		Settings.transport = .none
		Settings.smartConnect = false

		NotificationCenter.default.addObserver(self, selector: #selector(statusChanged), name: .vpnStatusChanged, object: nil)

		let testTask = Task {
			statusChanged()

			for await result in stream.stream {
				try Task.checkCancellation()

				return result
			}

			return false
		}

		let timeoutTask = Task {
			try await Task.sleep(nanoseconds: Self.timeout * NSEC_PER_SEC)
			testTask.cancel()
		}

		let result: Bool

		do {
			result = try await testTask.value
			timeoutTask.cancel()
		}
		catch {
			result = false // timeout
		}

		NotificationCenter.default.removeObserver(self, name: .vpnStatusChanged, object: nil)
		VpnManager.shared.disconnect(explicit: true)

		Settings.transport = originalTransport
		Settings.smartConnect = originalSmartConnect

		return result
	}

	@objc
	func statusChanged() {
		Logger.log("[\(String(describing: type(of: self)))] status=\(VpnManager.shared.status)")

		if lastStatus == VpnManager.shared.status {
			return
		}

		lastStatus = VpnManager.shared.status

		switch VpnManager.shared.status {
		case .notInstalled:
			VpnManager.shared.install()

			return

		case .disabled:
			VpnManager.shared.enable()

			return

		case .disconnected:
			// We try two times, because when the cache was old, Tor needs more memory and might
			// crash the NE, but on the second run it can run with the fresh cache and be all fine.
			if trialCounter > Self.retries - 1 {
				// Nos! Not working.

				stream.continuation.yield(false)
				stream.continuation.finish()
				return
			}
			else {
				trialCounter += 1
				VpnManager.shared.connect()

				return
			}

		case .evaluating, .connecting, .reasserting:
			// Ignore. Waiting for `connected`.
			return

		case .connected:
			// Yay! Success!
			stream.continuation.yield(true)
			stream.continuation.finish()
			return

		case .disconnecting:
			// Ignore. Waiting for `disconnected`.
			return

		default:
			// Nos! Not working.
			stream.continuation.yield(false)
			stream.continuation.finish()
			return
		}

	}
}

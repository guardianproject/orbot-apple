//
//  KindnessModeViewController.swift
//  Orbot Mac
//
//  Created by Benjamin Erhart on 21.07.25.
//  Copyright © 2020 - 2026 Guardian Project. All rights reserved.
//

import Cocoa
import IPtProxy

class KindnessModeViewController: NSViewController, IPtProxySnowflakeClientEventsProtocol {

	// MARK: Outlets

	@IBOutlet weak var stoppedContainer: NSView!

	@IBOutlet weak var iconIv: NSImageView! {
		didSet {
			iconIv.cell?.setAccessibilityElement(false)
		}
	}

	@IBOutlet weak var titleLb: NSTextField! {
		didSet {
			titleLb.stringValue = L10n.helpOthers
		}
	}

	@IBOutlet weak var descriptionLb: NSTextField! {
		didSet {
			descriptionLb.stringValue = L10n.kindnessModeDescription
		}
	}

	@IBOutlet weak var item1Lb: NSTextField! {
		didSet {
			item1Lb.stringValue = L10n.vpnWillBeSwitchedOff

		}
	}

	@IBOutlet weak var item2Lb: NSTextField! {
		didSet {
			item2Lb.stringValue = String(format: NSLocalizedString(
				"%@ It will not drain your battery.",
				comment: "Placeholder is bullet"), "•")
		}
	}

	@IBOutlet weak var item3Lb: NSTextField! {
		didSet {
			item3Lb.stringValue = String(format: NSLocalizedString(
				"%@ It will not slow down your internet.",
				comment: "Placeholder is bullet"), "•")
		}
	}

	@IBOutlet weak var item4Lb: NSTextField! {
		didSet {
			item4Lb.stringValue = String(
				format: NSLocalizedString("%@ It can be turned off anytime.",
										  comment: "Placeholder is bullet"), "•")
		}
	}

	@IBOutlet weak var activateBt: NSButton! {
		didSet {
			activateBt.title = L10n.activate
		}
	}

	@IBOutlet weak var startedContainer: NSView!

	@IBOutlet weak var iconStartedIv: NSImageView! {
		didSet {
			iconStartedIv.cell?.setAccessibilityElement(false)
		}
	}

	@IBOutlet weak var titleStartedLb: NSTextField! {
		didSet {
			titleStartedLb.stringValue = L10n.todayIsBetter
		}
	}

	@IBOutlet weak var toggleLb: NSTextField! {
		didSet {
			toggleLb.stringValue = L10n.kindnessMode
			toggleLb.setAccessibilityElement(false)
		}
	}

	@IBOutlet weak var toggleSw: NSSwitch! {
		didSet {
			toggleSw.setAccessibilityLabel(L10n.kindnessMode)
		}
	}

	@IBOutlet weak var weeklyLb: NSTextField! {
		didSet {
			weeklyLb.stringValue = L10n.weeklyTotal
		}
	}

	@IBOutlet weak var weeklyNumberLb: NSTextField!

	@IBOutlet weak var totalLb: NSTextField! {
		didSet {
			totalLb.stringValue = L10n.allTimeTotal
		}
	}

	@IBOutlet weak var totalNumberLb: NSTextField!


	// MARK: Private Properties

	private lazy var proxy: IPtProxySnowflakeProxy = {
		let proxy = SharedUtils.createSnowflakeProxy()
		proxy.clientEvents = self

		return proxy
	}()


	override func viewDidAppear() {
		super.viewDidAppear()

		view.window?.title = L10n.kindnessMode

		updateUi()
	}

	override func viewDidDisappear() {
		super.viewDidDisappear()

		proxy.stop()

		SharedUtils.releaseMappedPorts()
	}


	// MARK: Actions

	@IBAction func activate(_ sender: NSButton) {
		// Stop VPN. Snowflake Proxy only works, when not tunneled through Tor itself.
		SharedUtils.control(onlyTo: .disconnected)

		Task {
			let mapped = await SharedUtils.getMappedPorts()
			proxy.ephemeralMinPort = mapped.min
			proxy.ephemeralMaxPort = mapped.max

			proxy.start()
		}

		startedContainer.isHidden = false
		stoppedContainer.isHidden = true
		toggleSw.state = .on
	}

	@IBAction func deactivate(_ sender: NSSwitch) {
		proxy.stop()

		SharedUtils.releaseMappedPorts()

		stoppedContainer.isHidden = false
		startedContainer.isHidden = true
	}


	// MARK: IPtProxySnowflakeClientEvents

	func connected() {
		Settings.addOneSnowflakeHelped()

		DispatchQueue.main.async { [weak self] in
			self?.updateUi()
		}
	}

	func connectionFailed() {
		Logger.log("[SnowflakeClientEvent] connectionFailed")
	}

	func disconnected(_ country: String?) {
		Logger.log("[SnowflakeClientEvent] disconnected from country: \(country ?? "(nil)")")
	}

	func stats(_ connectionCount: Int, failedConnectionCount: Int64, inboundBytes: Int64, outboundBytes: Int64, inboundUnit: String?, outboundUnit: String?, summaryInterval: Int64)
	{
		guard connectionCount > 0 || failedConnectionCount > 0 || inboundBytes > 0 || outboundBytes > 0 || summaryInterval > 0
		else {
			return
		}

		let interval = TimeInterval(summaryInterval) / 1_000_000_000

		Logger.log(String(
			format: "[SnowflakeClientEvent] In the last %f seconds, there were %d completed successful and %d failed connections. Traffic Relayed ↓ %d %@ (%.2f %@%@), ↑ %d %@ (%.2f %@%@).  ",
			interval,
			connectionCount,
			failedConnectionCount,
			inboundBytes,
			inboundUnit ?? "?",
			Double(inboundBytes)/interval,
			inboundUnit ?? "?",
			"/s",
			outboundBytes,
			outboundUnit ?? "?",
			Double(outboundBytes)/interval,
			outboundUnit ?? "?",
			"/s"))
	}

	// MARK: Private Methods

	private func updateUi() {
		totalNumberLb.stringValue = Formatters.format(Settings.snowflakesHelpedTotal)
		weeklyNumberLb.stringValue = Formatters.format(Settings.snowflakesHelpedWeekly)
	}
}

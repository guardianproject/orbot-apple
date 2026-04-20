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

	@IBOutlet weak var description2Lb: NSTextField! {
		didSet {
			if #available(macOS 12, *),
			   let attributedString = try? NSMutableAttributedString(markdown: L10n.kindnessModeDescription2)
			{
				let range = NSRange(attributedString.string.startIndex..., in: attributedString.string)

				// Fix font. Otherwise, the bold part will show too small.
				attributedString.addAttribute(
					.font, value: NSFont.preferredFont(forTextStyle: .body),
					range: range)

				let ps = NSMutableParagraphStyle()
				ps.alignment = .center

				attributedString.addAttribute(.paragraphStyle, value: ps, range: range)

				description2Lb.attributedStringValue = attributedString
			}
			else {
				description2Lb.stringValue = L10n.kindnessModeDescription2
			}
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
			titleStartedLb.stringValue = L10n.kindnessMode
		}
	}

	@IBOutlet weak var toggleLb: NSTextField! {
		didSet {
			toggleLb.stringValue = L10n.enabled
			toggleLb.setAccessibilityElement(false)
		}
	}

	@IBOutlet weak var toggleSw: NSSwitch! {
		didSet {
			toggleSw.setAccessibilityLabel(L10n.kindnessMode)
		}
	}

	@IBOutlet weak var proxyQualityLb: NSTextField! {
		didSet {
			proxyQualityLb.stringValue = L10n.proxyQuality
		}
	}

	@IBOutlet weak var proxyQualityStateLb: NSTextField!

	@IBOutlet weak var impactLb: NSTextField! {
		didSet {
			impactLb.stringValue = L10n.yourImpactInNumbers
		}
	}

	@IBOutlet weak var weeklyLb: NSTextField! {
		didSet {
			weeklyLb.stringValue = L10n.thisWeek
		}
	}

	@IBOutlet weak var weeklyNumberLb: NSTextField!

	@IBOutlet weak var totalLb: NSTextField! {
		didSet {
			totalLb.stringValue = L10n.total
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

		FileManager.default.sfpLogFile?.truncate()

		Task {
			let mapped = await SharedUtils.getMappedPorts()
			proxy.ephemeralMinPort = mapped.min
			proxy.ephemeralMaxPort = mapped.max

			proxy.start()
		}

		startedContainer.isHidden = false
		stoppedContainer.isHidden = true
		toggleSw.state = .on
		proxyQualityStateLb.stringValue = L10n.proxyQualityType[IPtProxyNATUnknown] ?? IPtProxyNATUnknown
	}

	@IBAction func learnMore(_ sender: NSButton) {
		NSWorkspace.shared.open(SharedUtils.snowflakeHelpUrl)
	}

	@IBAction func deactivate(_ sender: NSSwitch) {
		proxy.stop()

		SharedUtils.releaseMappedPorts()

		stoppedContainer.isHidden = false
		startedContainer.isHidden = true
	}


	// MARK: IPtProxySnowflakeClientEventsProtocol

	func connected() {
		Settings.addOneSnowflakeHelped()

		DispatchQueue.main.async { [weak self] in
			self?.updateUi()
		}
	}

	func connectionFailed() {
		Logger.log("[SnowflakeClientEvent] connectionFailed", to: FileManager.default.sfpLogFile)
	}

	func disconnected(_ country: String?) {
		Logger.log("[SnowflakeClientEvent] disconnected from country: \(country ?? "(nil)")", to: FileManager.default.sfpLogFile)
	}

	func stats(_ connectionCount: Int, failedConnectionCount: Int64, inboundBytes: Int64, outboundBytes: Int64, inboundUnit: String?, outboundUnit: String?, summaryInterval: Int64)
	{
		let interval = TimeInterval(summaryInterval) / 1_000_000_000

		Logger.log(String(
			format: "[SnowflakeClientEvent] In the last %.0f seconds, there were %d completed successful and %d failed connections. Traffic Relayed ↓ %d %@ (%.2f %@%@), ↑ %d %@ (%.2f %@%@).  ",
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
			"/s"), to: FileManager.default.sfpLogFile)
	}

	func natTypeUpdated(_ natType: String?) {
		Task { @MainActor in
			proxyQualityStateLb.stringValue = L10n.proxyQualityType[natType ?? IPtProxyNATUnknown] ?? natType ?? IPtProxyNATUnknown
		}
	}


	// MARK: Private Methods

	private func updateUi() {
		totalNumberLb.stringValue = Formatters.format(Settings.snowflakesHelpedTotal)
		weeklyNumberLb.stringValue = Formatters.format(Settings.snowflakesHelpedWeekly)
	}
}

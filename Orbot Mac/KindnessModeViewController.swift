//
//  KindnessModeViewController.swift
//  Orbot Mac
//
//  Created by Benjamin Erhart on 21.07.25.
//  Copyright © 2020 - 2026 Guardian Project. All rights reserved.
//

import Cocoa
import IPtProxy

class KindnessModeViewController: NSViewController, IPtProxySnowflakeClientEventsProtocol, TestingViewController.Delegate, NSWindowDelegate {

	// MARK: Outlets

	@IBOutlet weak var stoppedContainer: NSView!

	@IBOutlet weak var iconIv: NSImageView! {
		didSet {
			iconIv.cell?.setAccessibilityElement(false)
		}
	}

	@IBOutlet weak var titleLb: NSTextField! {
		didSet {
			titleLb.stringValue = L10n.welcomeKindnessMode
		}
	}

	@IBOutlet weak var descriptionLb: NSTextField! {
		didSet {
			descriptionLb.stringValue = L10n.kindnessModeDescription
		}
	}

	@IBOutlet weak var censoredCountryWarningLb: NSTextField! {
		didSet {
			if #available(macOS 12, *),
			   let attributedString = try? NSMutableAttributedString(markdown: L10n.censoredCountryWarning)
			{
				let range = NSRange(attributedString.string.startIndex..., in: attributedString.string)

				// Fix font. Otherwise, the bold part will show too small.
				attributedString.addAttribute(
					.font, value: NSFont.preferredFont(forTextStyle: .body),
					range: range)

				let ps = NSMutableParagraphStyle()
				ps.alignment = .center

				attributedString.addAttribute(.paragraphStyle, value: ps, range: range)

				censoredCountryWarningLb.attributedStringValue = attributedString
			}
			else {
				censoredCountryWarningLb.stringValue = L10n.censoredCountryWarning
			}
		}
	}

	@IBOutlet weak var item1Lb: NSTextField! {
		didSet {
			item1Lb.stringValue = L10n.turnOffKindnessMode
		}
	}

	@IBOutlet weak var item2Lb: NSTextField! {
		didSet {
			item2Lb.stringValue = L10n.orbotVpnWillAutomaticallyTurnOff
		}
	}

	@IBOutlet weak var testBox: NSBox! {
		didSet {
			testBox.title = L10n.testConnection
		}
	}

	@IBOutlet weak var testExplainerLb: NSTextField! {
		didSet {
			testExplainerLb.stringValue = L10n.orbotWillTestYourConnection
		}
	}

	@IBOutlet weak var item3Lb: NSTextField! {
		didSet {
			item3Lb.stringValue = L10n.theTestWillTryToConnectDirectly
		}
	}

	@IBOutlet weak var item4Lb: NSTextField! {
		didSet {
			item4Lb.stringValue = L10n.ifYouAreUsingTorBridges
		}
	}

	@IBOutlet weak var acknowledgmentLb: NSTextField! {
		didSet {
			acknowledgmentLb.stringValue = L10n.iAcknowledgeIHaveReadTheAbove
		}
	}

	@IBOutlet weak var continueBt: NSButton! {
		didSet {
			continueBt.title = L10n.testConnection
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
			toggleLb.setAccessibilityElement(false)
		}
	}

	@IBOutlet weak var toggleSw: NSSwitch! {
		didSet {
			toggleSw.setAccessibilityLabel(L10n.kindnessMode)
			toggleSw.state = .off
		}
	}

	@IBOutlet weak var proxyQualityBox: NSBox! {
		didSet {
			let click = NSClickGestureRecognizer(target: self, action: #selector(upgrade))
			proxyQualityBox.addGestureRecognizer(click)
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

	private var natType: String?


	override func viewDidAppear() {
		super.viewDidAppear()

		view.window?.title = L10n.kindnessMode

		if Settings.hideInitialKindnessScene {
			toggleContainers()
		}

		updateUi()
	}

	override func viewDidDisappear() {
		super.viewDidDisappear()

		if proxy.isRunning() {
			toggleSw.state = .off
			toggleSnowflakeProxy(toggleSw)
		}
	}


	// MARK: Actions

	@IBAction func safetyToggle(_ sender: NSSwitch) {
		continueBt.isEnabled = sender.state == .on
	}

	@IBAction func activate(_ sender: NSButton) {
		if !sender.isEnabled {
			return
		}

		if VpnManager.shared.isStraightTorRunning {
			Settings.lastSnowflakeQualityCheckValid = true
		}

		guard Settings.lastSnowflakeQualityCheckValid else {
			return runTest()
		}

		Settings.hideInitialKindnessScene = true

		toggleSw.state = .on

		if startedContainer.isHidden {
			toggleContainers()
		}

		toggleSnowflakeProxy(toggleSw)
	}

	@IBAction func learnMore(_ sender: NSButton) {
		NSWorkspace.shared.open(SharedUtils.snowflakeHelpUrl)
	}

	@IBAction func toggleSnowflakeProxy(_ sender: NSSwitch) {
		if toggleSw.state == .on {
			Task {
				// Stop VPN. Snowflake Proxy only works, when not tunnelled through Tor itself.
				await SharedUtils.control(onlyTo: .disconnected)


				FileManager.default.sfpLogFile?.truncate()

				let mapped = await SharedUtils.getMappedPorts()
				proxy.ephemeralMinPort = mapped.min
				proxy.ephemeralMaxPort = mapped.max

				do {
					try proxy.start()
				}
				catch {
					// This should not happen, but we log it, if it does, just in case.
					Logger.log(level: .error, error.localizedDescription)
				}
			}
		}
		else {
			proxy.stop()

			SharedUtils.releaseMappedPorts()

			natType = nil
		}

		updateUi()
	}

	@objc func upgrade() {
		if natType == IPtProxyNATRestricted {
			let alert = NSAlert()
			alert.messageText = L10n.upgradeYourSnowflakeProxy
			alert.informativeText = String(format: "%@\n\n%@", L10n.yourProxyCanBeMorePowerful, L10n.toUpgradeEnableUPnP)

			alert.runModal()
		}
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
		let interval = TimeInterval(summaryInterval) / Double(NSEC_PER_SEC)

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
		self.natType = natType

		Task { @MainActor in
			updateUi()
		}
	}


	// MARK: TestingViewController.Delegate

	func finished(success: Bool) {
		if success {
			Settings.lastSnowflakeQualityCheckValid = true
		}

		activate(continueBt)
	}


	// MARK: Private Methods

	private func updateUi() {
		toggleLb.stringValue = toggleSw.state == .on ? L10n.enabled : L10n.disabled

		let natType = toggleSw.state == .on ? (natType ?? IPtProxyNATUnknown) : IPtProxyNATUnknown
		let proxyQualityText = L10n.proxyQualityType[natType] ?? natType

		if natType == IPtProxyNATRestricted {
			let at = NSMutableAttributedString(string: "• \(proxyQualityText) \u{276f}") // Chevron right

			// Color the bullet red.
			let range = NSRange(at.string.startIndex ..< at.string.index(at.string.startIndex, offsetBy: 1), in: at.string)
			at.addAttribute(.foregroundColor, value: NSColor.systemRed, range: range)

			proxyQualityStateLb.attributedStringValue = at
		}
		else {
			proxyQualityStateLb.stringValue = proxyQualityText
		}

		totalNumberLb.stringValue = Formatters.format(Settings.snowflakesHelpedTotal)
		weeklyNumberLb.stringValue = Formatters.format(Settings.snowflakesHelpedWeekly)
	}

	private func toggleContainers() {
		let toShow: NSView
		let toHide: NSView

		if stoppedContainer.isHidden {
			toShow = stoppedContainer
			toHide = startedContainer
		}
		else {
			toShow = startedContainer
			toHide = stoppedContainer
		}

		toShow.isHidden = false
		toHide.isHidden = true
	}

	private func runTest() {
		if let wc = NSStoryboard.main?.instantiateController(withIdentifier: "testingScene") as? NSWindowController,
		   let win = wc.window,
		   let vc = wc.contentViewController as? TestingViewController
		{
			vc.delegate = self

			NSApp.runModal(for: win)

			win.close()
		}
	}
}

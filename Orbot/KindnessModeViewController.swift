//
//  KindnessModeViewController.swift
//  Orbot
//
//  Created by Benjamin Erhart on 16.07.25.
//  Copyright © 2020 - 2026 Guardian Project. All rights reserved.
//

import UIKit
import IPtProxy
import IPtProxyUI

class KindnessModeViewController: UIViewController, IPtProxySnowflakeClientEventsProtocol,
									TestingViewController.Delegate
{

	// MARK: Outlets

	@IBOutlet weak var stoppedContainer: UIView!

	@IBOutlet weak var titleLb: UILabel! {
		didSet {
			titleLb.text = L10n.welcomeKindnessMode
		}
	}

	@IBOutlet weak var descriptionLb: UILabel! {
		didSet {
			descriptionLb.text = L10n.kindnessModeDescription
		}
	}

	@IBOutlet weak var censoredCountryWarningLb: UILabel! {
		didSet {
			censoredCountryWarningLb.text = L10n.censoredCountryWarning
		}
	}

	@IBOutlet weak var continueBt: UIButton! {
		didSet {
			continueBt.setTitle(L10n.cont)
		}
	}

	@IBOutlet weak var learnMoreBt: UIButton! {
		didSet {
			learnMoreBt.setTitle(L10n.learnMore, for: .normal)
		}
	}

	@IBOutlet weak var startedContainer: UIView!

	@IBOutlet weak var titleStartedLb: UILabel! {
		didSet {
			titleStartedLb.text = L10n.kindnessMode
		}
	}

	@IBOutlet weak var toggleLb: UILabel! {
		didSet {
			toggleLb.isAccessibilityElement = false
		}
	}

	@IBOutlet weak var toggleSw: UISwitch! {
		didSet {
			toggleSw.accessibilityLabel = L10n.kindnessMode
			toggleSw.isOn = false
		}
	}

	@IBOutlet weak var proxyQualityLb: UILabel! {
		didSet {
			proxyQualityLb.text = L10n.proxyQuality
		}
	}

	@IBOutlet weak var proxyQualityStateLb: UILabel!

	@IBOutlet weak var impactLb: UILabel! {
		didSet {
			impactLb.text = L10n.yourImpactInNumbers
		}
	}

	@IBOutlet weak var weeklyLb: UILabel! {
		didSet {
			weeklyLb.text = L10n.thisWeek
		}
	}

	@IBOutlet weak var weeklyNumberLb: UILabel!

	@IBOutlet weak var totalLb: UILabel! {
		didSet {
			totalLb.text = L10n.total
		}
	}

	@IBOutlet weak var totalNumberLb: UILabel!


	// MARK: Private Properties

	private lazy var proxy: IPtProxySnowflakeProxy = {
		let proxy = SharedUtils.createSnowflakeProxy()
		proxy.clientEvents = self

		return proxy
	}()

	private var natType: String?


	override func viewDidLoad() {
		super.viewDidLoad()

		tabBarItem?.title = L10n.kindnessMode
		tabBarItem?.badgeColor = .accent

		if Settings.hideInitialKindnessScene {
			toggleContainers()
		}

		updateUi()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		if proxy.isRunning() {
			toggleSw.isOn = false
			toggleSnowflakeProxy()
		}
	}


	// MARK: Actions

	@IBAction func activate() {
//#if targetEnvironment(simulator)
//		Settings.lastSnowflakeQualityCheckValid = true
//#else
		if VpnManager.shared.isStraightTorRunning {
			Settings.lastSnowflakeQualityCheckValid = true
		}
//#endif

		guard Settings.lastSnowflakeQualityCheckValid else {
			return runTest()
		}

		Settings.hideInitialKindnessScene = true

		toggleSw.isOn = true

		if startedContainer.isHidden {
			toggleContainers(animated: true)
		}

		toggleSnowflakeProxy()
	}

	@IBAction func learnMore() {
		UIApplication.shared.open(SharedUtils.snowflakeHelpUrl)
	}

	@IBAction func toggleSnowflakeProxy() {
		if toggleSw.isOn {
			UIApplication.shared.isIdleTimerDisabled = true
			Dimmer.shared.start()

			FileManager.default.sfpLogFile?.truncate()

			Task {
				// Stop VPN. Snowflake Proxy only works, when not tunnelled through Tor itself.
				await SharedUtils.control(onlyTo: .disconnected)

				let mapped = await SharedUtils.getMappedPorts()
				proxy.ephemeralMinPort = mapped.min
				proxy.ephemeralMaxPort = mapped.max

				DispatchQueue.global(qos: .utility).async { [weak self] in
					do {
						try self?.proxy.start()
					}
					catch {
						// This should not happen, but we log it, if it does, just in case.
						Logger.log(level: .error, error.localizedDescription)
					}
				}
			}
		}
		else {
			proxy.stop()

			SharedUtils.releaseMappedPorts()

			Dimmer.shared.stop()
			UIApplication.shared.isIdleTimerDisabled = false

			natType = nil
		}

		updateUi()
	}

	@IBAction func upgrade() {
		if natType == IPtProxyNATRestricted {
			AlertHelper.present(
				self,
				message: String(format: "%@\n\n%@", L10n.yourProxyCanBeMorePowerful, L10n.toUpgradeEnableUPnP),
				title: L10n.upgradeYourSnowflakeProxy)
		}
	}


	// MARK: IPtProxySnowflakeClientEventsProtocol

	func connected() {
		Settings.addOneSnowflakeHelped()

		Task { @MainActor in
			updateUi()
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

		activate()
	}


	// MARK: Private Methods

	private func updateUi() {
		toggleLb.text = toggleSw.isOn ? L10n.enabled : L10n.disabled

		let natType = toggleSw.isOn ? (natType ?? IPtProxyNATUnknown) : IPtProxyNATUnknown
		let proxyQualityText = L10n.proxyQualityType[natType] ?? natType

		if natType == IPtProxyNATRestricted {
			let at = NSMutableAttributedString(string: "• \(proxyQualityText) \u{276f}") // Chevron right

			// Color the bullet red.
			let range = NSRange(at.string.startIndex ..< at.string.index(at.string.startIndex, offsetBy: 1), in: at.string)
			at.addAttribute(.foregroundColor, value: UIColor.systemRed, range: range)

			proxyQualityStateLb.attributedText = at
		}
		else {
			proxyQualityStateLb.text = proxyQualityText
		}

		totalNumberLb.text = Formatters.format(Settings.snowflakesHelpedTotal)
		weeklyNumberLb.text = Formatters.format(Settings.snowflakesHelpedWeekly)

		tabBarItem?.badgeValue = toggleSw.isOn ? "✓" : nil
	}

	private func toggleContainers(animated: Bool = false) {
		let toShow: UIView
		let toHide: UIView
		let toTell: UILabel

		if stoppedContainer.isHidden {
			toShow = stoppedContainer
			toHide = startedContainer
			toTell = titleLb
		}
		else {
			toShow = startedContainer
			toHide = stoppedContainer
			toTell = titleStartedLb
		}

		if animated {
			toShow.layer.opacity = 0
			toShow.isHidden = false
			toShow.accessibilityElementsHidden = false

			UIView.animate(
				withDuration: 0.3,
				animations: {
					toShow.layer.opacity = 1
					toHide.layer.opacity = 0
				},
				completion: { _ in
					toHide.isHidden = true
					toHide.layer.opacity = 1
					toHide.accessibilityElementsHidden = true

					UIAccessibility.post(notification: .screenChanged, argument: toTell)
				})
		}
		else {
			toShow.isHidden = false
			toHide.isHidden = true

			UIAccessibility.post(notification: .screenChanged, argument: toTell)
		}
	}

	private func runTest() {
		let vc = UIStoryboard.main.instantiateViewController(KindnessModeExplainerViewController.self)
		vc.delegate = self

		present(inNav: vc, view: continueBt)
	}
}

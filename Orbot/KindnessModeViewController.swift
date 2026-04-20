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

class KindnessModeViewController: UIViewController, IPtProxySnowflakeClientEventsProtocol {

	// MARK: Outlets

	@IBOutlet weak var stoppedContainer: UIView!

	@IBOutlet weak var titleLb: UILabel! {
		didSet {
			titleLb.text = L10n.helpOthers
		}
	}

	@IBOutlet weak var descriptionLb: UILabel! {
		didSet {
			descriptionLb.text = L10n.kindnessModeDescription
		}
	}

	@IBOutlet weak var description2Lb: UILabel! {
		didSet {
			if let attributedString = try? NSMutableAttributedString(markdown: L10n.kindnessModeDescription2)
			{
				let range = NSRange(attributedString.string.startIndex..., in: attributedString.string)

				// Fix font. Otherwise, the bold part will show too small.
				attributedString.addAttribute(
					.font, value: UIFont.preferredFont(forTextStyle: .body),
					range: range)

				let ps = NSMutableParagraphStyle()
				ps.alignment = .center

				attributedString.addAttribute(.paragraphStyle, value: ps, range: range)

				description2Lb.attributedText = attributedString
			}
			else {
				description2Lb.text = L10n.kindnessModeDescription2
			}
		}
	}

	@IBOutlet weak var item1Lb: UILabel! {
		didSet {
			item1Lb.text = String(format: NSLocalizedString(
				"%@ App needs to stay in the foreground.",
				comment: "Placeholder is bullet"), "•")
		}
	}

	@IBOutlet weak var item2Lb: UILabel! {
		didSet {
			item2Lb.text = L10n.vpnWillBeSwitchedOff
		}
	}

	@IBOutlet weak var item3Lb: UILabel! {
		didSet {
			item3Lb.text = String(format: NSLocalizedString(
				"%@ Screen will be dimmed. (Turn device screen down to switch off screen like during a phone call.)",
				comment: "Placeholder is bullet"), "•")
		}
	}

	@IBOutlet weak var item4Lb: UILabel! {
		didSet {
			item4Lb.text = String(format: NSLocalizedString(
				"%@ Connect to power while letting it run.",
				comment: "Placeholder is bullet"), "•")
		}
	}

	@IBOutlet weak var activateBt: UIButton! {
		didSet {
			activateBt.setTitle(L10n.activate, for: .normal)
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
			toggleLb.text = L10n.enabled
			toggleLb.isAccessibilityElement = false
		}
	}

	@IBOutlet weak var toggleSw: UISwitch! {
		didSet {
			toggleSw.accessibilityLabel = L10n.kindnessMode
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


	override func viewDidLoad() {
		super.viewDidLoad()

		tabBarItem?.title = L10n.kindnessMode
		tabBarItem?.badgeColor = .accent

		updateUi()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		if proxy.isRunning() {
			deactivate()
		}
	}


	// MARK: Actions

	@IBAction func activate() {
		// Stop VPN. Snowflake Proxy only works, when not tunneled through Tor itself.
		SharedUtils.control(onlyTo: .disconnected)

		UIApplication.shared.isIdleTimerDisabled = true
		Dimmer.shared.start()

		FileManager.default.sfpLogFile?.truncate()

		Task {
			let mapped = await SharedUtils.getMappedPorts()
			proxy.ephemeralMinPort = mapped.min
			proxy.ephemeralMaxPort = mapped.max

			DispatchQueue.global(qos: .utility).async { [weak self] in
				self?.proxy.start()
			}
		}

		startedContainer.layer.opacity = 0
		startedContainer.isHidden = false
		startedContainer.accessibilityElementsHidden = false
		toggleSw.isOn = true
		proxyQualityStateLb.text = L10n.proxyQualityType[IPtProxyNATUnknown] ?? IPtProxyNATUnknown

		UIView.animate(
			withDuration: 0.3,
			animations: { [weak self] in
				self?.stoppedContainer.layer.opacity = 0
				self?.startedContainer.layer.opacity = 1
			},
			completion: { [weak self] _ in
				self?.stoppedContainer.isHidden = true
				self?.stoppedContainer.accessibilityElementsHidden = true

				self?.tabBarItem?.badgeValue = "✓"

				UIAccessibility.post(notification: .screenChanged, argument: self?.titleStartedLb)
			})
	}

	@IBAction func learnMore() {
		UIApplication.shared.open(SharedUtils.snowflakeHelpUrl)
	}

	@IBAction func deactivate() {
		stopProxy()

		stoppedContainer.layer.opacity = 0
		stoppedContainer.isHidden = false
		stoppedContainer.accessibilityElementsHidden = false

		UIView.animate(
			withDuration: 0.3,
			animations: { [weak self] in
				self?.stoppedContainer.layer.opacity = 1
				self?.startedContainer.layer.opacity = 0
			},
			completion: { [weak self] _ in
				self?.startedContainer.isHidden = true
				self?.startedContainer.accessibilityElementsHidden = true

				self?.tabBarItem?.badgeValue = nil

				UIAccessibility.post(notification: .screenChanged, argument: self?.titleLb)
			})
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
			proxyQualityStateLb.text = L10n.proxyQualityType[natType ?? IPtProxyNATUnknown] ?? natType ?? IPtProxyNATUnknown
		}
	}


	// MARK: Private Methods

	private func updateUi() {
		totalNumberLb.text = Formatters.format(Settings.snowflakesHelpedTotal)
		weeklyNumberLb.text = Formatters.format(Settings.snowflakesHelpedWeekly)
	}

	private func stopProxy() {
		proxy.stop()

		SharedUtils.releaseMappedPorts()

		Dimmer.shared.stop()
		UIApplication.shared.isIdleTimerDisabled = false
	}
}

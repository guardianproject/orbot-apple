//
//  KindnessModeViewController.swift
//  Orbot
//
//  Created by Benjamin Erhart on 16.07.25.
//  Copyright © 2025 Guardian Project. All rights reserved.
//

import UIKit
import IPtProxy
import IPtProxyUI

class KindnessModeViewController: UIViewController, IPtProxySnowflakeClientConnectedProtocol {

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

	@IBOutlet weak var startedContainer: UIView!

	@IBOutlet weak var titleStartedLb: UILabel! {
		didSet {
			titleStartedLb.text = L10n.todayIsBetter
		}
	}

	@IBOutlet weak var toggleLb: UILabel! {
		didSet {
			toggleLb.text = L10n.kindnessMode
		}
	}

	@IBOutlet weak var toggleSw: UISwitch!

	@IBOutlet weak var weeklyLb: UILabel! {
		didSet {
			weeklyLb.text = L10n.weeklyTotal
		}
	}

	@IBOutlet weak var weeklyNumberLb: UILabel!

	@IBOutlet weak var totalLb: UILabel! {
		didSet {
			totalLb.text = L10n.allTimeTotal
		}
	}

	@IBOutlet weak var totalNumberLb: UILabel!


	// MARK: Private Properties

	private lazy var proxy: IPtProxySnowflakeProxy = {
		let proxy = SharedUtils.createSnowflakeProxy()
		proxy.clientConnected = self

		return proxy
	}()


	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.title = L10n.kindnessMode

		updateUi()
	}


	// MARK: Actions

	@IBAction func stop() {
		stopProxy()

		let vc = UIStoryboard.main.instantiateViewController(MainViewController.self)
		navigationController?.setViewControllers([vc], animated: true)
	}

	@IBAction func activate() {
		// Stop VPN. Snowflake Proxy only works, when not tunneled through Tor itself.
		SharedUtils.control(onlyTo: .disconnected)

		UIApplication.shared.isIdleTimerDisabled = true
		Dimmer.shared.start()

		Task {
			let mapped = await SharedUtils.getMappedPorts()
			proxy.ephemeralMinPort = mapped.min
			proxy.ephemeralMaxPort = mapped.max

			proxy.start()
		}

		startedContainer.layer.opacity = 0
		startedContainer.isHidden = false
		toggleSw.isOn = true

		UIView.animate(
			withDuration: 0.3,
			animations: { [weak self] in
				self?.stoppedContainer.layer.opacity = 0
				self?.startedContainer.layer.opacity = 1
			},
			completion: { [weak self] _ in
				self?.stoppedContainer.isHidden = true
			})
	}

	@IBAction func deactivate() {
		stopProxy()

		stoppedContainer.layer.opacity = 0
		stoppedContainer.isHidden = false

		UIView.animate(
			withDuration: 0.3,
			animations: { [weak self] in
				self?.stoppedContainer.layer.opacity = 1
				self?.startedContainer.layer.opacity = 0
			},
			completion: { [weak self] _ in
				self?.startedContainer.isHidden = true
			})
	}


	// MARK: IPtProxySnowflakeClientConnectedProtocol

	func connected() {
		Settings.addOneSnowflakeHelped()

		DispatchQueue.main.async { [weak self] in
			self?.updateUi()
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

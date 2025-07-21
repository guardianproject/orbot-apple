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
			titleLb.text = NSLocalizedString("Help others connect to Tor", comment: "")
		}
	}

	@IBOutlet weak var descriptionLb: UILabel! {
		didSet {
			descriptionLb.text = NSLocalizedString(
				"Kindness mode allows your device to be a bridge for others. It helps people use Tor in places where it is blocked.",
				comment: "")
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
			item2Lb.text = String(format: NSLocalizedString(
				"%@ Screen will be dimmed. (Turn device screen down to switch off screen like during a phone call.)",
				comment: "Placeholder is bullet"), "•")
		}
	}

	@IBOutlet weak var item3Lb: UILabel! {
		didSet {
			item3Lb.text = String(format: NSLocalizedString(
				"%@ Connect to power while letting it run.",
				comment: "Placeholder is bullet"), "•")
		}
	}

	@IBOutlet weak var item4Lb: UILabel! {
		didSet {
			item4Lb.text = String(format: NSLocalizedString(
				"%@ It can be turned off anytime.",
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
			titleStartedLb.text = NSLocalizedString("Today is better because of you.", comment: "")
		}
	}

	@IBOutlet weak var toggleLb: UILabel! {
		didSet {
			toggleLb.text = NSLocalizedString("Kindness Mode", comment: "")
		}
	}

	@IBOutlet weak var toggleSw: UISwitch!

	@IBOutlet weak var weeklyLb: UILabel! {
		didSet {
			weeklyLb.text = NSLocalizedString("Weekly Total", comment: "")
		}
	}

	@IBOutlet weak var weeklyNumberLb: UILabel!

	@IBOutlet weak var totalLb: UILabel! {
		didSet {
			totalLb.text = NSLocalizedString("All Time Total", comment: "")
		}
	}

	@IBOutlet weak var totalNumberLb: UILabel!


	// MARK: Private Properties

	private lazy var proxy: IPtProxySnowflakeProxy = {
		let proxy = IPtProxySnowflakeProxy()
		proxy.capacity = 1
		proxy.pollInterval = 120
		proxy.stunServer = BuiltInBridges.shared?.snowflake?.first?.ice?.components(separatedBy: ",")
			.filter({ !$0.isEmpty }).randomElement() ?? ""
		proxy.clientConnected = self

		return proxy
	}()


	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.title = NSLocalizedString("Kindness Mode", comment: "")

		updateUi()
	}


	// MARK: Actions

	@IBAction func stop() {
		stopProxy()

		let vc = UIStoryboard.main.instantiateViewController(MainViewController.self)
		navigationController?.setViewControllers([vc], animated: true)
	}

	@IBAction func activate() {
		UIApplication.shared.isIdleTimerDisabled = true
		Dimmer.shared.start()

		proxy.start()

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

		Dimmer.shared.stop()
		UIApplication.shared.isIdleTimerDisabled = false
	}
}

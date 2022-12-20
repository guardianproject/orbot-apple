//
//  MainViewController.swift
//  Orbot
//
//  Created by Benjamin Erhart on 20.05.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import UIKit
import Tor
import IPtProxyUI
import MBProgressHUD
import NetworkExtension

class MainViewController: UIViewController {

	@IBOutlet weak var logBt: UIBarButtonItem? {
		didSet {
			logBt?.accessibilityLabel = NSLocalizedString("Open or Close Log", comment: "")
			logBt?.accessibilityIdentifier = "open_close_log"
		}
	}

	@IBOutlet weak var settingsBt: UIBarButtonItem? {
		didSet {
			settingsBt?.accessibilityLabel = L10n.settings
			settingsBt?.accessibilityIdentifier = "settings_menu"

			updateMenu()
		}
	}

	@IBOutlet weak var refreshBt: UIBarButtonItem? {
		didSet {
			refreshBt?.accessibilityLabel = L10n.newCircuits
		}
	}

	@IBOutlet weak var statusIcon: UIImageView!
	@IBOutlet weak var shadowImg: UIImageView!
	@IBOutlet weak var statusLb: UILabel!
	@IBOutlet weak var statusSubLb: UILabel!

	@IBOutlet weak var changeExitBt: UIButton? {
		didSet {
			changeExitBt?.setTitle(NSLocalizedString("Limit Exit Countries", comment: ""))
		}
	}

	@IBOutlet weak var controlBt: UIButton!

	@IBOutlet weak var control2Bt: UIButton! {
		didSet {
			control2Bt.setAttributedTitle(SharedUtils.smartConnectButtonLabel(buttonFontSize: control2Bt.titleLabel?.font.pointSize))
		}
	}
	@IBOutlet weak var control2BtHeight: NSLayoutConstraint!

	@IBOutlet weak var configureBt: UIButton! {
		didSet {
			configureBt.setTitle(NSLocalizedString("Choose How to Connect", comment: ""))
		}
	}

	@IBOutlet weak var logContainer: UIView! {
		didSet {
			// Only round top right corner.
			logContainer.layer.cornerRadius = 9
			logContainer.layer.maskedCorners = [.layerMaxXMinYCorner]
		}
	}

	@IBOutlet weak var logSc: UISegmentedControl! {
		didSet {
			logSc.setTitle("Tor", forSegmentAt: 0)
			logSc.setTitle(L10n.bridges, forSegmentAt: 1)
			logSc.setTitle(L10n.circuits, forSegmentAt: 2)

#if DEBUG
			if Config.extendedLogging {
				logSc.insertSegment(withTitle: "SFP", at: 3, animated: false)
				logSc.insertSegment(withTitle: "VPN", at: 4, animated: false)
				logSc.insertSegment(withTitle: "LL", at: 5, animated: false)
				logSc.insertSegment(withTitle: "LC", at: 6, animated: false)
				logSc.insertSegment(withTitle: "WS", at: 7, animated: false)
			}
#endif
		}
	}

	@IBOutlet weak var logTv: UITextView!


	private let bridgesConfDelegate = SharedUtils()


	override func viewDidLoad() {
		super.viewDidLoad()

		let callback: (Notification) -> Void = { [weak self] notification in
			self?.updateUi(notification)
		}

		let nc = NotificationCenter.default
		nc.addObserver(forName: .vpnStatusChanged, object: nil, queue: .main, using: callback)
		nc.addObserver(forName: .vpnProgress, object: nil, queue: .main, using: callback)

		updateUi()
	}

	override func selectAll(_ sender: Any?) {
		logTv.selectAll(sender)
	}


	// MARK: Actions

	@IBAction func toggleLogs() {
		if logContainer.isHidden {
			logContainer.transform = CGAffineTransform(translationX: -logContainer.bounds.width, y: 0)
			logContainer.isHidden = false

			UIView.animate(withDuration: 0.5) {
				self.logContainer.transform = CGAffineTransform(translationX: 0, y: 0)
			} completion: { _ in
				self.changeLog()
			}
		}
		else {
			hideLogs()
		}
	}

	@IBAction func hideLogs() {
		if !logContainer.isHidden {
			UIView.animate(withDuration: 0.5) {
				self.logContainer.transform = CGAffineTransform(translationX: -self.logContainer.bounds.width, y: 0)
			} completion: { _ in
				self.logContainer.isHidden = true
				self.logContainer.transform = CGAffineTransform(translationX: 0, y: 0)

				Logger.tailFile(nil)
			}
		}
	}

	func showSettings(_ sender: UIBarButtonItem? = nil) {
		present(inNav: SettingsViewController(), button: sender ?? settingsBt)
	}

	@discardableResult
	func showAuth(_ sender: UIBarButtonItem? = nil) -> AuthViewController {
		let vc = AuthViewController(style: .grouped)

		present(inNav: vc, button: sender ?? settingsBt)

		return vc
	}

	@IBAction func changeBridges(_ sender: UIButton? = nil) {
		let vc = BridgesConfViewController()
		vc.delegate = bridgesConfDelegate

		present(inNav: vc, view: sender ?? configureBt)
	}

	@discardableResult
	func showApiAccess(_ sender: UIBarButtonItem? = nil) -> ApiAccessViewController {
		let vc = ApiAccessViewController(style: .grouped)

		present(inNav: vc, button: sender ?? settingsBt)

		return vc
	}

	@IBAction func changeExit(_ sender: UIButton? = nil) {
		present(inNav: ChangeExitViewController(), view: sender ?? changeExitBt)
	}

	@IBAction func refresh(_ sender: UIButton? = nil) {
		let hud = MBProgressHUD.showAdded(to: view, animated: true)
		hud.mode = .determinate
		hud.progress = 0
		hud.label.text = L10n.newCircuits

		let showError = { (error: Error) in
			hud.progress = 1
			hud.label.text = L10n.error
			hud.detailsLabel.text = error.localizedDescription
			hud.hide(animated: true, afterDelay: 3)
		}

		VpnManager.shared.getCircuits { [weak self] circuits, error in
			if let error = error {
				return showError(error)
			}

			hud.progress = 0.5

			VpnManager.shared.closeCircuits(circuits) { success, error in
				if let error = error {
					return showError(error)
				}

				hud.progress = 1

				if self?.logContainer.isHidden == false && self?.logSc.selectedSegmentIndex == 1 {
					self?.changeLog()
				}

				hud.hide(animated: true, afterDelay: 0.5)
			}
		}
	}

	@IBAction func control(_ sender: UIButton? = nil) {
		if sender == control2Bt {
			Settings.smartConnect = true
		}

		SharedUtils.control(startOnly: false)
	}

	@IBAction func changeLog() {
		switch logSc.selectedSegmentIndex {
		case 1:
			// Shows the content of the Snowflake or Obfs4proxy log file.
			Logger.tailFile(Settings.transport.logFile, update)

		case 2:
			Logger.tailFile(nil)

			SharedUtils.getCircuits { [weak self] text in
				self?.logTv.text = text
				self?.logTv.scrollToBottom()
			}

#if DEBUG
		case 3:
			// Shows the content of the Snowflake Proxy log file.
			Logger.tailFile(FileManager.default.sfpLogFile, update)

		case 4:
			// Shows the content of the VPN log file.
			Logger.tailFile(FileManager.default.vpnLogFile, update)

		case 5:
			// Shows the content of the leaf log file.
			Logger.tailFile(FileManager.default.leafLogFile, update)

		case 6:
			// Shows the content of the leaf config file.
			Logger.tailFile(FileManager.default.leafConfFile, update)

		case 7:
			// Shows the content of the GCD webserver log file.
			Logger.tailFile(FileManager.default.wsLogFile, update)
#endif

		default:
			Logger.tailFile(FileManager.default.torLogFile, update)
		}
	}

	@IBAction func controlSnowflakeProxy() {
#if DEBUG
		if Config.snowflakeProxyExperiment {
			SharedUtils.controlSnowflakeProxy()
		}
		else {
			showContentBlocker()
		}
#else
		showContentBlocker()
#endif
	}

	@IBAction func showContentBlocker() {
		present(inNav: ContentBlockerViewController(), button: settingsBt)
	}


	// MARK: Observers

	@objc func updateUi(_ notification: Notification? = nil) {

		refreshBt?.isEnabled = VpnManager.shared.status == .connected

		let (statusIconName, buttonTitle, statusText, statusSubtext, _) = SharedUtils.updateUi(notification, buttonFontSize: controlBt.titleLabel?.font.pointSize)

		animateOrbie = statusIconName == .imgOrbieStarting

		statusIcon.image = UIImage(named: statusIconName)
		controlBt.setAttributedTitle(buttonTitle)
		control2BtHeight.constant = Settings.smartConnect || VpnManager.shared.status != .disconnected ? 0 : 64
		statusLb.attributedText = statusText
		statusSubLb.text = statusSubtext

		logSc.setEnabled(Settings.transport != .none, forSegmentAt: 1)
	}


	// MARK: Public Methods

	func updateMenu() {
		var elements = [UIMenuElement]()

		elements.append(UIAction(
			title: NSLocalizedString("Kindness Mode", comment: ""),
			image: UIImage(systemName: "heart.fill"),
			handler: { _ in
				// TODO
			}))
		elements.last?.accessibilityIdentifier = "kindness_mode"

		elements.append(UIAction(
			title: L10n.authCookies,
			image: UIImage(systemName: "key"),
			handler: { [weak self] _ in
				self?.showAuth()
			}))
		elements.last?.accessibilityIdentifier = "auth_cookies"

		if !Settings.apiAccessTokens.isEmpty {
			elements.append(UIAction(
				title: NSLocalizedString("API Access", comment: ""),
				image: UIImage(systemName: "lock.shield"),
				handler: { [weak self] _ in
					self?.showApiAccess()
				}))
			elements.last?.accessibilityIdentifier = "api_access"
		}

		elements.append(UIAction(
			title: NSLocalizedString("Content Blocker", comment: ""),
			image: UIImage(systemName: "checkerboard.shield"),
			handler: { [weak self] _ in
				self?.showContentBlocker()
			}))
		elements.last?.accessibilityIdentifier = "content_blocker"

		elements.append(UIAction(
			title: L10n.settings,
			image: UIImage(systemName: "gearshape"),
			handler: { [weak self] _ in
				self?.showSettings()
			}))
		elements.last?.accessibilityIdentifier = "settings"

		elements.append(UIAction(
			title: NSLocalizedString("About", comment: ""),
			image: nil,
			handler: { _ in
				// TODO
			}))
		elements.last?.accessibilityIdentifier = "about"

		settingsBt?.menu = nil

		settingsBt?.menu = UIMenu(title: "", children: elements)
	}


	// MARK: Private Methods

	private func update(_ logText: String) {
		let atBottom = logTv.isAtBottom

		logTv.text = logText

		if atBottom {
			logTv.scrollToBottom()
		}
	}

	private var animateOrbie = false {
		didSet {
			if animateOrbie && !oldValue {
				animateOrbie()
			}
		}
	}

	private func animateOrbie(up: Bool = true) {
		guard animateOrbie || !up else {
			return
		}

		UIView.animate(
			withDuration: 0.5,
			delay: 0,
			options: up ? .curveEaseOut : .curveEaseIn,
			animations: { [weak self] in

				// Make Orbie jump.
				self?.statusIcon.transform = .init(translationX: 0, y: up ? -32 : 0)

				// Let the shadow follow along.
				self?.shadowImg.transform = .init(scaleX: up ? 0.75 : 1, y: up ? 0.75 : 1)
			}) { [weak self] _ in
				self?.animateOrbie(up: !up)
			}
	}
}

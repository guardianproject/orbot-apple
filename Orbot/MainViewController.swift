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
import ProgressHUD
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
	@IBOutlet weak var statusIconWidth: NSLayoutConstraint!
	@IBOutlet weak var shadowImg: UIImageView!
	@IBOutlet weak var shadowImgHeight: NSLayoutConstraint!
	@IBOutlet weak var statusLb: UILabel!
	@IBOutlet weak var statusSubLb: UILabel!

	@IBOutlet weak var controlBt: UIButton!

	@IBOutlet weak var smartConnectSw: UISwitch! {
		didSet {
			Settings.smartConnect = false
		}
	}
	@IBOutlet weak var smartConnectLb: UILabel! {
		didSet {
			smartConnectLb.text = L10n.runSmartConnectToFindTheBestWay
		}
	}

	@IBOutlet weak var configureBt: UIButton! {
		didSet {
			configureBt.setTitle(L10n.chooseHowToConnect)
			configureBt.accessibilityIdentifier = "bridge_configuration"
		}
	}

	@IBOutlet weak var clearCacheBt: UIButton! {
		didSet {
			clearCacheBt.setTitle(NSLocalizedString("Clear Tor Cache", comment: ""))
		}
	}

	@IBOutlet weak var kindnessModeBt: UIButton! {
		didSet {
			kindnessModeBt.setTitle(NSLocalizedString("Kindness Mode", comment: ""))
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


	private static let obName = "Onion Browser"

	private var obInstalled: Bool {
		UIApplication.shared.canOpenURL(URL.obCheckTor)
	}

	private var heightsCache = [UIView: CGFloat]()


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
		present(inNav: BridgesViewController(), view: sender ?? configureBt)
	}

	@discardableResult
	func showApiAccess(_ sender: UIBarButtonItem? = nil) -> ApiAccessViewController {
		let vc = ApiAccessViewController(style: .grouped)

		present(inNav: vc, button: sender ?? settingsBt)

		return vc
	}

	@IBAction func changeExit(_ sender: UIBarButtonItem? = nil) {
		present(inNav: ChangeExitViewController(), button: sender ?? settingsBt)
	}

	@IBAction func refresh(_ sender: UIButton? = nil) {
		ProgressHUD.progress(L10n.newCircuits, 0)

		let showError = { (error: Error) in
			ProgressHUD.failed(error.localizedDescription, delay: 3)
		}

		VpnManager.shared.getCircuits { [weak self] circuits, error in
			if let error = error {
				return showError(error)
			}

			ProgressHUD.progress(0.5)

			VpnManager.shared.closeCircuits(circuits) { success, error in
				if let error = error {
					return showError(error)
				}

				ProgressHUD.succeed()

				if self?.logContainer.isHidden == false && self?.logSc.selectedSegmentIndex == 1 {
					self?.changeLog()
				}
			}
		}
	}

	@IBAction func control(_ sender: UIButton? = nil) {
		SharedUtils.control()
	}

	@IBAction func toggleSmartConnect(_ sender: UIView) {
		guard smartConnectSw.isEnabled else {
			return
		}

		if sender != smartConnectSw {
			smartConnectSw.setOn(!smartConnectSw.isOn, animated: true)
		}

		Settings.smartConnect = smartConnectSw.isOn

		updateUi()
	}

	@IBAction func clearCache(_ sender: UIButton? = nil) {
		TorHelpers.clearCache()

		clearCacheBt.setTitle(NSLocalizedString("Cleared!", comment: ""))

		DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
			self?.clearCacheBt.setTitle(NSLocalizedString("Clear Tor Cache", comment: ""))
		}
	}

	@IBAction func kindnessMode(_ sender: UIButton? = nil) {
		SharedUtils.control(onlyTo: .disconnected)

		let vc = UIStoryboard.main.instantiateViewController(KindnessModeViewController.self)
		navigationController?.setViewControllers([vc], animated: true)
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

	@IBAction func showContentBlocker() {
		present(inNav: ContentBlockerViewController(), button: settingsBt)
	}


	// MARK: Observers

	@objc func updateUi(_ notification: Notification? = nil) {

		refreshBt?.isEnabled = VpnManager.shared.status == .connected

		let (statusIconName, showShadow, buttonTitle, statusText, statusSubtext, showConfButton) = SharedUtils.updateUi(
			notification, buttonFontSize: controlBt.titleLabel?.font.pointSize)

		animateOrbie = statusIconName == .imgOrbieStarting

		statusIcon.image = UIImage(named: statusIconName)

		if showShadow {
			statusIconWidth.constant = 128
			shadowImg.isHidden = false
			shadowImgHeight.constant = 18
		}
		else {
			statusIconWidth.constant = 192
			shadowImg.isHidden = true
			shadowImgHeight.constant = 0
		}

		statusLb.attributedText = statusText
		statusSubLb.text = statusSubtext
		controlBt.setAttributedTitle(buttonTitle)

		smartConnectSw.isOn = Settings.smartConnect
		smartConnectSw.isEnabled = VpnManager.shared.status == .disconnected || VpnManager.shared.status == .disabled
		reallyHide(smartConnectSw.superview, true) //!showConfButton)

		reallyHide(configureBt, true) //!showConfButton)

		clearCacheBt.isEnabled = VpnManager.shared.status == .disconnected
		reallyHide(clearCacheBt, !showConfButton || Settings.alwaysClearCache)

		logSc.setEnabled(Settings.transport != .none, forSegmentAt: 1)
	}


	// MARK: Public Methods

	func updateMenu() {
		var elements = [UIMenuElement]()

//		elements.append(UIAction(
//			title: LocalizedString("Kindness Mode", comment: ""),
//			image: UIImage(systemName: "heart.fill"),
//			handler: { _ in
//				// TODO
//			}))
//		elements.last?.accessibilityIdentifier = "kindness_mode"

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
			title: NSLocalizedString("Limit Exit Countries", comment: ""),
			image: UIImage(systemName: "globe.europe.africa"),
			handler: { [weak self] _ in
				self?.changeExit()
			}))

		elements.append(UIAction(
			title: L10n.settings,
			image: UIImage(systemName: "gearshape"),
			handler: { [weak self] _ in
				self?.showSettings()
			}))
		elements.last?.accessibilityIdentifier = "settings"

//		elements.append(UIMenu(options: .displayInline, children: [UIAction(
//			title: obInstalled
//				? String(format: NSLocalizedString("Open %@", comment: "Placeholder is 'Onion Browser'"), Self.obName)
//				: String(format: NSLocalizedString("Install %@", comment: "Placeholder is 'Onion Browser'"), Self.obName),
//			image: UIImage(systemName: "network.badge.shield.half.filled"),
//			handler: { [weak self] _ in
//				UIApplication.shared.open(self?.obInstalled ?? false ? URL.obCheckTor : URL.obAppStore)
//			})]))

//		elements.append(UIAction(
//			title: LocalizedString("About", comment: ""),
//			image: nil,
//			handler: { _ in
//				// TODO
//			}))
//		elements.last?.accessibilityIdentifier = "about"

		settingsBt?.menu = nil

		settingsBt?.menu = UIMenu(children: elements)
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

	private func reallyHide(_ view: UIView?, _ hide: Bool = true) {
		guard let view = view, view.isHidden != hide else {
			return
		}

		if hide {
			for c in view.constraints {
				if c.firstAttribute == .height {
					if c.constant > 0 && heightsCache[view] == nil {
						heightsCache[view] = c.constant
					}

					c.isActive = false
				}
			}

			view.heightAnchor.constraint(equalToConstant: 0).isActive = true
		}
		else {
			for c in view.constraints {
				if c.firstAttribute == .height {
					c.isActive = false
				}
			}

			if let height = heightsCache[view] {
				view.heightAnchor.constraint(equalToConstant: height).isActive = true
				heightsCache[view] = nil
			}
		}

		view.isHidden = hide
	}
}

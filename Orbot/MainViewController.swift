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

class MainViewController: UIViewController, BridgesConfDelegate {

	@IBOutlet weak var logBt: UIBarButtonItem? {
		didSet {
			logBt?.accessibilityLabel = NSLocalizedString("Open or Close Log", comment: "")
			logBt?.accessibilityIdentifier = "open_close_log"
		}
	}

	@IBOutlet weak var settingsBt: UIBarButtonItem? {
		didSet {
			settingsBt?.accessibilityLabel = NSLocalizedString("Settings", comment: "")
			settingsBt?.accessibilityIdentifier = "settings_menu"

			updateMenu()
		}
	}

	@IBOutlet weak var refreshBt: UIBarButtonItem? {
		didSet {
			refreshBt?.accessibilityLabel = NSLocalizedString("Build new Circuits", comment: "")
		}
	}

	@IBOutlet weak var statusIcon: UIImageView!
	@IBOutlet weak var controlBt: UIButton!
	@IBOutlet weak var statusLb: UILabel!

	@IBOutlet weak var contentBlockerBt: UIButton! {
		didSet {
			contentBlockerBt.setTitle(NSLocalizedString("Content Blocker", comment: ""))
		}
	}

	@IBOutlet weak var versionLb: UILabel! {
		didSet {
			versionLb.text = String(format: NSLocalizedString("Version %@, Build %@", comment: ""),
									Bundle.main.version, Bundle.main.build)
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
			logSc.setTitle(NSLocalizedString("Log", comment: ""), forSegmentAt: 0)
			logSc.setTitle(NSLocalizedString("Circuits", comment: ""), forSegmentAt: 1)

#if DEBUG
			if Config.extendedLogging {
				logSc.insertSegment(withTitle: "VPN", at: 2, animated: false)
				logSc.insertSegment(withTitle: "LL", at: 3, animated: false)
				logSc.insertSegment(withTitle: "LC", at: 4, animated: false)
				logSc.insertSegment(withTitle: "WS", at: 5, animated: false)
			}
#endif
		}
	}

	@IBOutlet weak var logTv: UITextView!

	private static let nf: NumberFormatter = {
		let nf = NumberFormatter()
		nf.numberStyle = .percent
		nf.maximumFractionDigits = 1

		return nf
	}()

	private var logFsObject: DispatchSourceFileSystemObject? {
		didSet {
			oldValue?.cancel()
		}
	}

	private var logText = ""


	override func viewDidLoad() {
		super.viewDidLoad()

		let nc = NotificationCenter.default

		nc.addObserver(self, selector: #selector(updateUi), name: .vpnStatusChanged, object: nil)
		nc.addObserver(self, selector: #selector(updateUi), name: .vpnProgress, object: nil)

		updateUi()
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

				self.tailFile(nil)
			}
		}
	}

	func updateMenu() {
		var group1 = [UIAction]()
		var group2 = [UIAction]()

		group1.append(UIAction(
			title: NSLocalizedString("Settings", comment: ""),
			image: UIImage(systemName: "gearshape"),
			handler: { [weak self] _ in
				self?.showSettings()
			}))
		group1.last?.accessibilityIdentifier = "settings"

		group1.append(UIAction(
			title: NSLocalizedString("Auth Cookies", comment: ""),
			image: UIImage(systemName: "key"),
			handler: { [weak self] _ in
				self?.showAuth()
			}))
		group1.last?.accessibilityIdentifier = "auth_cookies"

		group1.append(UIAction(
			title: NSLocalizedString("Bridge Configuration", bundle: Bundle.iPtProxyUI, comment: "#bc-ignore!"),
			image: UIImage(systemName: "network.badge.shield.half.filled"),
			handler: { [weak self] _ in
				self?.changeBridges()
			}))
		group1.last?.accessibilityIdentifier = "bridge_configuration"

		if !Settings.apiAccessTokens.isEmpty {
			group1.append(UIAction(
				title: NSLocalizedString("API Access", comment: ""),
				image: UIImage(systemName: "lock.shield"),
				handler: { [weak self] _ in
					self?.showApiAccess()
				}))
			group1.last?.accessibilityIdentifier = "api_access"
		}

		group2.append(UIAction(
			title: NSLocalizedString("Content Blocker", comment: ""),
			image: UIImage(systemName: "checkerboard.shield")) { [weak self] _ in
				self?.showContentBlocker()
			})
		group2.last?.accessibilityIdentifier = "content_blocker"

		settingsBt?.menu = nil

		settingsBt?.menu = UIMenu(title: "", children: [
			UIMenu(title: "", options: .displayInline, children: group1),
			UIMenu(title: "", options: .displayInline, children: group2)
		])
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

	func changeBridges(_ sender: UIBarButtonItem? = nil) {
		let vc = BridgesConfViewController()
		vc.delegate = self

		present(inNav: vc, button: sender ?? settingsBt)
	}

	@discardableResult
	func showApiAccess(_ sender: UIBarButtonItem? = nil) -> ApiAccessViewController {
		let vc = ApiAccessViewController(style: .grouped)

		present(inNav: vc, button: sender ?? settingsBt)

		return vc
	}

	@IBAction func refresh(_ sender: UIBarButtonItem? = nil) {
		let hud = MBProgressHUD.showAdded(to: view, animated: true)
		hud.mode = .determinate
		hud.progress = 0
		hud.label.text = NSLocalizedString("Build new Circuits", comment: "")

		let showError = { (error: Error) in
			hud.progress = 1
			hud.label.text = NSLocalizedString("Error", bundle: Bundle.iPtProxyUI, comment: "#bc-ignore!")
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

	@IBAction func control() {
		control(startOnly: false)
	}

	func control(startOnly: Bool) {

		// Enable, if disabled.
		if VpnManager.shared.confStatus == .disabled {
			return VpnManager.shared.enable { [weak self] success in
				if success && VpnManager.shared.confStatus == .enabled {
					self?.control(startOnly: startOnly)
				}
			}
		}

		if startOnly && ![NEVPNStatus.disconnected, .disconnecting].contains(VpnManager.shared.sessionStatus) {
			return
		}

		// Install first, if not installed.
		else if VpnManager.shared.confStatus == .notInstalled {
			return VpnManager.shared.install()
		}

		switch VpnManager.shared.sessionStatus {
		case .connected, .connecting:
			VpnManager.shared.disconnect()

		case .disconnected, .disconnecting:
			VpnManager.shared.connect()

		default:
			break
		}
	}

	@IBAction func changeLog() {
		switch logSc.selectedSegmentIndex {
		case 1:
			tailFile(nil)

			logTv.text = nil

			VpnManager.shared.getCircuits { [weak self] circuits, error in
				let circuits = TorCircuit.filter(circuits)

				var text = ""

				var i = 1

				for c in circuits {
					text += "Circuit \(c.circuitId ?? String(i))\n"

					var j = 1

					for n in c.nodes ?? [] {
						var country = n.localizedCountryName ?? n.countryCode ?? ""

						if !country.isEmpty {
							country = " (\(country))"
						}

						text += "\(j): \(n.nickName ?? n.fingerprint ?? n.ipv4Address ?? n.ipv6Address ?? "unknown node")\(country)\n"

						j += 1
					}

					text += "\n"

					i += 1
				}

				self?.logTv.text = text
				self?.logTv.scrollToBottom()
			}

#if DEBUG
		case 2:
			// Shows the content of the VPN log file.
			tailFile(FileManager.default.vpnLogFile)

		case 3:
			// Shows the content of the leaf log file.
			tailFile(FileManager.default.leafLogFile)

		case 4:
			// Shows the content of the leaf config file.
			tailFile(FileManager.default.leafConfFile)

		case 5:
			// Shows the content of the GCD webserver log file.
			tailFile(FileManager.default.wsLogFile)
#endif

		default:
			tailFile(FileManager.default.torLogFile)
		}
	}

	@IBAction func showContentBlocker() {
		present(inNav: ContentBlockerViewController(), button: settingsBt)
	}


	// MARK: Observers

	@objc func updateUi(_ notification: Notification? = nil) {

		refreshBt?.isEnabled = VpnManager.shared.sessionStatus == .connected

		switch VpnManager.shared.sessionStatus {
		case .connected, .connecting:
			statusIcon.image = UIImage(named: "TorOn")
			controlBt.setTitle(NSLocalizedString("Stop", comment: ""))

		case .invalid:
			statusIcon.image = UIImage(named: "TorOff")
			controlBt.setTitle(NSLocalizedString("Install", comment: ""))

		default:
			statusIcon.image = UIImage(named: "TorOff")
			controlBt.setTitle(NSLocalizedString("Start", comment: ""))
		}

		if let error = VpnManager.shared.error {
			statusLb.textColor = .systemRed
			statusLb.text = error.localizedDescription
		}
		else if VpnManager.shared.confStatus != .enabled {
			statusLb.textColor = .white
			statusLb.text = VpnManager.shared.confStatus.description
		}
		else {
			var progress = ""

			if notification?.name == .vpnProgress,
			   let raw = notification?.object as? Float {

				progress = MainViewController.nf.string(from: NSNumber(value: raw)) ?? ""
			}

			var transport = ""

			switch VpnManager.shared.sessionStatus {
			case .connected, .connecting, .reasserting:
				transport = Settings.transport.description

			default:
				break
			}

			statusLb.textColor = .white
			statusLb.text = [VpnManager.shared.sessionStatus.description,
							 transport, progress].joined(separator: " ")
		}
	}


	// MARK: BridgesConfDelegate

	var transport: Transport {
		get {
			Settings.transport
		}
		set {
			Settings.transport = newValue
		}
	}

	var customBridges: [String]? {
		get {
			Settings.customBridges
		}
		set {
			Settings.customBridges = newValue
		}
	}

	func save() {
		VpnManager.shared.configChanged()
	}


	// MARK: Private Methods

	private func tailFile(_ url: URL?) {

		// Stop and remove the previous watched content.
		// (Will implicitely call #stop through `didSet` hook!)
		logFsObject = nil

		guard let url = url,
			let fh = try? FileHandle(forReadingFrom: url)
		else {
			return
		}

		let ui = { [weak self] in
			let data = fh.readDataToEndOfFile()

			if let content = String(data: data, encoding: .utf8) {
				let atBottom = self?.logTv.isAtBottom ?? false

				self?.logText.append(content)

				self?.logTv.text = self?.logText

				if atBottom {
					self?.logTv.scrollToBottom()
				}
			}
		}

		logText = ""
		ui()

		logFsObject = DispatchSource.makeFileSystemObjectSource(
			fileDescriptor: fh.fileDescriptor,
			eventMask: [.extend, .delete, .link],
			queue: .main)

		logFsObject?.setEventHandler { [weak self] in
			guard let data = self?.logFsObject?.data else {
				return
			}

			if data.contains(.delete) || data.contains(.link) {
				DispatchQueue.main.async {
					self?.tailFile(url)
				}
			}

			if data.contains(.extend) {
				ui()
			}
		}

		logFsObject?.setCancelHandler { [weak self] in
			try? fh.close()

			self?.logText = ""
		}

		logFsObject?.resume()
	}
}

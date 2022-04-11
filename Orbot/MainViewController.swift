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

	private static let purposeFilter = [
		TorCircuit.purposeGeneral,
		TorCircuit.purposeHsClientRend,
		TorCircuit.purposeHsServiceRend]

	@IBOutlet weak var logBt: UIBarButtonItem? {
		didSet {
			logBt?.accessibilityLabel = NSLocalizedString("Open or Close Log", comment: "")
			logBt?.accessibilityIdentifier = "open_close_log"
		}
	}

	@IBOutlet weak var settingsBt: UIBarButtonItem? {
		didSet {
			settingsBt?.accessibilityLabel = NSLocalizedString("Settings", comment: "")
			settingsBt?.accessibilityIdentifier = "settings"

			settingsBt?.menu = UIMenu(title: "", children: [
				UIAction(title: NSLocalizedString("Settings", comment: ""),
						 image: UIImage(systemName: "gearshape"),
						 handler: { [weak self] _ in
							 self?.showSettings()
						 }),
				UIAction(title: NSLocalizedString("Auth Cookies", comment: ""),
						 image: UIImage(systemName: "key"),
						 handler: { [weak self] _ in
							 self?.showAuth()
						 }),
				UIAction(title: NSLocalizedString("Bridge Configuration", bundle: Bundle.iPtProxyUI, comment: "#bc-ignore!"),
						 image: UIImage(systemName: "network.badge.shield.half.filled"),
						 handler: { [weak self] _ in
							 self?.changeBridges()
						 }),
			])

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
		}
	}

	@IBOutlet weak var logTv: UITextView!

	private static let nf: NumberFormatter = {
		let nf = NumberFormatter()
		nf.numberStyle = .percent
		nf.maximumFractionDigits = 1

		return nf
	}()

	private var logFsObject: DispatchSourceFileSystemObject?

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

				self.logFsObject?.cancel()
				self.logFsObject = nil
			}
		}
	}

	func changeBridges(_ sender: UIBarButtonItem? = nil) {
		let vc = BridgesConfViewController()
		vc.delegate = self

		present(inNav: vc, button: sender ?? settingsBt)
	}

	@discardableResult
	func showAuth(_ sender: UIBarButtonItem? = nil) -> AuthViewController {
		let vc = AuthViewController(style: .grouped)

		present(inNav: vc, button: sender ?? settingsBt)

		return vc
	}

	func showSettings(_ sender: UIBarButtonItem? = nil) {
		present(inNav: SettingsViewController(), button: sender ?? settingsBt)
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
			logFsObject?.cancel()
			logFsObject = nil

			logTv.text = nil

			VpnManager.shared.getCircuits { [weak self] circuits, error in
				var text = ""

				var i = 1

				for c in circuits {
					if c.purpose == nil
						|| !Self.purposeFilter.contains(c.purpose!)
						|| c.buildFlags?.contains(TorCircuit.buildFlagIsInternal) ?? false
						|| c.buildFlags?.contains(TorCircuit.buildFlagOneHopTunnel) ?? false
						|| c.nodes?.isEmpty ?? true
					{
						continue
					}

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

		case 2:
			// Shows the content of the leaf config file.
			// Only for development!
			logFsObject?.cancel()
			logFsObject = nil

			logTv.text = nil

			if let url = FileManager.default.leafConfFile {
				logTv.text = try? String(contentsOf: url)
			}

		default:
			createLogFsObject()
		}
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

	private func createLogFsObject() {
		guard logFsObject == nil,
			let url = FileManager.default.torLogFile,
			let fh = try? FileHandle(forReadingFrom: url)
		else {
			return
		}

		let ui = { [weak self] in
			let data = fh.readDataToEndOfFile()

			if let content = String(data: data, encoding: .utf8) {
				self?.logText.append(content)

				self?.logTv.text = self?.logText
				self?.logTv.scrollToBottom()
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
				self?.logFsObject?.cancel()
				self?.logFsObject = nil

				DispatchQueue.main.async {
					self?.createLogFsObject()
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

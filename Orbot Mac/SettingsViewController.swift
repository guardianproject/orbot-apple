//
//  SettingsViewController.swift
//  Orbot Mac
//
//  Created by Benjamin Erhart on 23.08.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import Cocoa
import IPtProxyUI

class SettingsViewController: NSViewController, NSTextFieldDelegate {

	@IBOutlet weak var tab1: NSTabViewItem! {
		didSet {
			tab1.label = L10n.general
		}
	}

	@IBOutlet weak var box1: NSBox! {
		didSet {
			box1.title = L10n.automaticRestart
		}
	}

	@IBOutlet weak var restartOnErrorLb: NSTextField! {
		didSet {
			restartOnErrorLb.stringValue = L10n.automaticallyRestartOnError
			restartOnErrorLb.cell?.setAccessibilityElement(false)
		}
	}

	@IBOutlet weak var restartOnErrorSw: NSSwitch! {
		didSet {
			restartOnErrorSw.state = Settings.restartOnError ? .on : .off
			restartOnErrorSw.setAccessibilityLabel(L10n.automaticallyRestartOnError)
		}
	}

	@IBOutlet weak var box2: NSBox! {
		didSet {
			box2.title = L10n.onionOnlyMode
		}
	}

	@IBOutlet weak var onionOnlyLb: NSTextField! {
		didSet {
			onionOnlyLb.stringValue = L10n.disableForNonOnionTraffic
			onionOnlyLb.cell?.setAccessibilityElement(false)
		}
	}

	@IBOutlet weak var onionOnlySw: NSSwitch! {
		didSet {
			onionOnlySw.state = Settings.onionOnly ? .on : .off
			onionOnlySw.setAccessibilityLabel(L10n.disableForNonOnionTraffic)
		}
	}

	@IBOutlet weak var onionOnlyExplLb: NSTextField! {
		didSet {
			onionOnlyExplLb.stringValue = L10n.attentionAnonymity
		}
	}

	@IBOutlet weak var box3: NSBox! {
		didSet {
			box3.title = L10n.proxy
		}
	}

	@IBOutlet weak var proxyDescLb: NSTextField! {
		didSet {
			proxyDescLb.stringValue = L10n.proxyDesc
		}
	}

	@IBOutlet weak var proxyTypeLb: NSTextField! {
		didSet {
			proxyTypeLb.stringValue = L10n.proxyType
			proxyTypeLb.setAccessibilityElement(false)
		}
	}

	@IBOutlet weak var proxyTypePb: NSPopUpButton! {
		didSet {
			proxyTypePb.selectItem(withTitle: Settings.proxy?.scheme ?? "socks5")
		}
	}

	@IBOutlet weak var proxyHostLb: NSTextField! {
		didSet {
			proxyHostLb.stringValue = L10n.proxyHost
			proxyHostLb.setAccessibilityElement(false)
		}
	}

	@IBOutlet weak var proxyHostTf: NSTextField! {
		didSet {
			proxyHostTf.setAccessibilityLabel(L10n.proxyHost)
			proxyHostTf.stringValue = Settings.proxy?.host ?? ""
		}
	}

	@IBOutlet weak var proxyPortLb: NSTextField! {
		didSet {
			proxyPortLb.stringValue = L10n.proxyPort
			proxyPortLb.setAccessibilityElement(false)
		}
	}

	@IBOutlet weak var proxyPortTf: NSTextField! {
		didSet {
			proxyPortTf.setAccessibilityLabel(L10n.proxyPort)
			proxyPortTf.placeholderString = URL.defaultProxyPort(for: Settings.proxy?.scheme)

			if let port = Settings.proxy?.port {
				proxyPortTf.stringValue = String(port)
			}
		}
	}

	@IBOutlet weak var proxyUsernameLb: NSTextField! {
		didSet {
			proxyUsernameLb.stringValue = L10n.proxyUsername
			proxyUsernameLb.setAccessibilityElement(false)
		}
	}

	@IBOutlet weak var proxyUsernameTf: NSTextField! {
		didSet {
			proxyUsernameTf.setAccessibilityLabel(L10n.proxyUsername)
			proxyUsernameTf.stringValue = Settings.proxy?.user ?? ""
		}
	}

	@IBOutlet weak var proxyPasswordLb: NSTextField! {
		didSet {
			proxyPasswordLb.stringValue = L10n.proxyPassword
			proxyPasswordLb.setAccessibilityElement(false)
		}
	}

	@IBOutlet weak var proxyPasswordTf: NSTextField! {
		didSet {
			proxyPasswordTf.setAccessibilityLabel(L10n.proxyPassword)
			proxyPasswordTf.stringValue = Settings.proxy?.password ?? ""
		}
	}

	@IBOutlet weak var versionLb: NSTextField! {
		didSet {
			versionLb.stringValue = L10n.version
		}
	}

	@IBOutlet weak var tab2: NSTabViewItem! {
		didSet {
			tab2.label = L10n.nodeConfiguration
		}
	}

	@IBOutlet weak var entryNodesLb: NSTextField! {
		didSet {
			entryNodesLb.stringValue = L10n.entryNodes
		}
	}

	@IBOutlet weak var entryNodesExplLb: NSTextField! {
		didSet {
			entryNodesExplLb.stringValue = L10n.entryNodesExplanation
		}
	}

	@IBOutlet weak var entryNodesTf: NSTextField! {
		didSet {
			entryNodesTf.stringValue = Settings.entryNodes ?? ""
			entryNodesTf.setAccessibilityLabel(L10n.entryNodes)
			entryNodesTf.delegate = self
		}
	}

	@IBOutlet weak var exitNodesLb: NSTextField! {
		didSet {
			exitNodesLb.stringValue = L10n.exitNodes
		}
	}

	@IBOutlet weak var exitNodesExplLb: NSTextField! {
		didSet {
			exitNodesExplLb.stringValue = L10n.exitNodesExplanation
		}
	}

	@IBOutlet weak var exitNodeBt: NSButton!

	@IBOutlet weak var exitNodesTf: NSTextField! {
		didSet {
			exitNodesTf.stringValue = Settings.exitNodes ?? ""
			exitNodesTf.setAccessibilityLabel(L10n.exitNodes)
			exitNodesTf.delegate = self
		}
	}

	@IBOutlet weak var excludeNodesLb: NSTextField! {
		didSet {
			excludeNodesLb.stringValue = L10n.excludeNodes
		}
	}

	@IBOutlet weak var excludeNodesExplLb: NSTextField! {
		didSet {
			excludeNodesExplLb.stringValue = L10n.excludeNodesExplanation
		}
	}

	@IBOutlet weak var excludeNodesTf: NSTextField! {
		didSet {
			excludeNodesTf.stringValue = Settings.excludeNodes ?? ""
			excludeNodesTf.setAccessibilityLabel(L10n.excludeNodes)
			excludeNodesTf.delegate = self
		}
	}

	@IBOutlet weak var strictNodesLb: NSTextField! {
		didSet {
			strictNodesLb.stringValue = L10n.excludeNodesNever
			strictNodesLb.cell?.setAccessibilityElement(false)
		}
	}

	@IBOutlet weak var strictNodesSw: NSSwitch! {
		didSet {
			strictNodesSw.state = Settings.strictNodes ? .on : .off
			strictNodesSw.setAccessibilityLabel(L10n.excludeNodesNever)

		}
	}

	@IBOutlet weak var nodesExplLb: NSTextField! {
		didSet {
			nodesExplLb.stringValue = L10n.settingsExplanation1
		}
	}

	@IBOutlet weak var tab3: NSTabViewItem! {
		didSet {
			tab3.label = L10n.advancedTorConf
		}
	}

	@IBOutlet weak var box4: NSBox! {
		didSet {
			box4.title = L10n.isolateDestAddr
		}
	}

	@IBOutlet weak var isolateDestAddrLb: NSTextField! {
		didSet {
			isolateDestAddrLb.stringValue = L10n.isolateDestAddrDescription
			isolateDestAddrLb.cell?.setAccessibilityElement(false)
		}
	}

	@IBOutlet weak var isolateDestAddrSw: NSSwitch! {
		didSet {
			isolateDestAddrSw.state = Settings.isolateDestAddr ? .on : .off
			isolateDestAddrSw.setAccessibilityLabel(L10n.isolateDestAddrDescription)
		}
	}

	@IBOutlet weak var torConfRefBt: NSButton! {
		didSet {
			torConfRefBt.title = L10n.torConfReference
		}
	}

	@IBOutlet weak var torConfTf: NSTextField! {
		didSet {
			torConfTf.stringValue = Settings.advancedTorConf?.joined(separator: "\n") ?? ""
			torConfTf.delegate = self
		}
	}

	@IBOutlet weak var torConfExplLb: NSTextField! {
		didSet {
			torConfExplLb.stringValue = L10n.settingsExplanation2
		}
	}

	@IBOutlet weak var box5: NSBox! {
		didSet {
			box5.title = L10n.maintenance
		}
	}

	@IBOutlet weak var clearCacheBt: NSButton! {
		didSet {
			clearCacheBt.title = L10n.clearTorCache
		}
	}

	@IBOutlet weak var box6: NSBox! {
		didSet {
			box6.title = L10n.expert
		}
	}

	@IBOutlet weak var smartConnectTimeoutLb: NSTextField! {
		didSet {
			smartConnectTimeoutLb.stringValue = L10n.smartConnectTimeout
			smartConnectTimeoutLb.cell?.setAccessibilityElement(false)
		}
	}

	@IBOutlet weak var smartConnectTimeoutTf: NSTextField! {
		didSet {
			smartConnectTimeoutTf.stringValue = String(Int(Settings.smartConnectTimeout))
			smartConnectTimeoutTf.setAccessibilityLabel(L10n.smartConnectTimeout)
		}
	}


	override func viewDidAppear() {
		super.viewDidAppear()

		view.window?.title = L10n.settings

		statusChanged()

		let nc = NotificationCenter.default

		nc.addObserver(forName: .vpnStatusChanged, object: nil, queue: .main) { [weak self] _ in
			self?.statusChanged()
		}

		nc.addObserver(forName: .exitNodesChanged, object: nil, queue: .main) { [weak self] _ in
			self?.exitNodesTf.stringValue = Settings.exitNodes ?? ""
		}

		nc.addObserver(forName: .exitCountrySelectorClosed, object: nil, queue: .main) { [weak self] _ in
			self?.exitNodeBt.state = .on
		}
	}


	// MARK: Actions

	@IBAction func changeRestartOnError(_ sender: NSSwitch) {
		Settings.restartOnError = sender.state == .on

		VpnManager.shared.updateRestartOnError()
	}

	@IBAction func changeOnionOnly(_ sender: NSSwitch) {
		if sender.state == .on {
			let alert = NSAlert()
			alert.messageText = L10n.warning
			alert.informativeText = L10n.settingsExplanation3
			alert.addButton(withTitle: L10n.activate)
			alert.addButton(withTitle: IPtProxyUI.L10n.cancel)

			let response = alert.runModal()

			switch response {
			case .alertFirstButtonReturn:
				Settings.onionOnly = true

			default:
				sender.state = .off
			}
		}
		else {
			if Settings.onionOnly {
				Settings.onionOnly = false
				VpnManager.shared.disconnect(explicit: true)
			}
		}
	}

	@IBAction func changeProxy(_ sender: NSView) {
		var urlc = URLComponents()

		urlc.scheme = proxyTypePb.selectedItem?.title
		urlc.host = proxyHostTf.stringValue

		if let port = Int(proxyPortTf.stringValue), port > 0 && port < 65536 {
			urlc.port = port
		}
		else {
			urlc.port = nil
		}

		urlc.user = proxyUsernameTf.stringValue
		urlc.password = proxyPasswordTf.stringValue

		if !(urlc.host?.isEmpty ?? true) {
			Settings.proxy = urlc.url
		}
		else {
			Settings.proxy = nil
		}

		proxyPortTf.placeholderString = URL.defaultProxyPort(for: Settings.proxy?.scheme)
	}

	@IBAction func changeEntryNodes(_ sender: NSTextField) {
		Settings.entryNodes = sender.stringValue
	}

	@IBAction func changeExitNodes(_ sender: NSTextField) {
		Settings.exitNodes = sender.stringValue
	}

	@IBAction func changeExcludeNodes(_ sender: NSTextField) {
		Settings.excludeNodes = sender.stringValue
	}

	@IBAction func changeStrictNodes(_ sender: NSSwitch) {
		Settings.strictNodes = sender.state == .on
	}

	@IBAction func changeIsolateDestAddr(_ sender: NSSwitch) {
		Settings.isolateDestAddr = sender.state == .on
	}

	@IBAction func showTorConfRef(_ sender: NSButton) {
		NSWorkspace.shared.open(SharedUtils.torConfUrl)
	}

	@IBAction func changeTorConf(_ sender: NSTextField) {
		Settings.advancedTorConf = sender.stringValue
			.components(separatedBy: .newlines)
			.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
	}

	@IBAction func clearCache(_ sender: NSButton) {
		TorHelpers.clearCache()

		let alert = NSAlert()
		alert.messageText = L10n.cleared

		alert.runModal()
	}


	// NSTextFieldDelegate

	/**
	 Let the user enter new lines instead of end editing and marking the whole text.
	 */
	func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
		if commandSelector == #selector(insertNewline) {
			textView.insertNewlineIgnoringFieldEditor(self)

			return true
		}

		return false
	}


	// MARK: Private Methods

	private func statusChanged() {
		clearCacheBt.isEnabled = !VpnManager.shared.isConnected
	}
}

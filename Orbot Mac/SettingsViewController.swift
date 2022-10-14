//
//  SettingsViewController.swift
//  Orbot Mac
//
//  Created by Benjamin Erhart on 23.08.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import Cocoa
import IPtProxyUI

class SettingsViewController: NSViewController {

	@IBOutlet weak var infoLb: NSTextField! {
		didSet {
			infoLb.stringValue = L10n.settingsEfectAfterRestart
		}
	}

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
		}
	}
	
	@IBOutlet weak var restartOnErrorSw: NSSwitch! {
		didSet {
			restartOnErrorSw.state = Settings.restartOnError ? .on : .off
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
		}
	}

	@IBOutlet weak var onionOnlySw: NSSwitch! {
		didSet {
			onionOnlySw.state = Settings.onionOnly ? .on : .off
		}
	}

	@IBOutlet weak var onionOnlyExplLb: NSTextField! {
		didSet {
			onionOnlyExplLb.stringValue = L10n.attentionAnonymity
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

	@IBOutlet weak var exitNodesTf: NSTextField! {
		didSet {
			exitNodesTf.stringValue = Settings.exitNodes ?? ""
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
		}
	}

	@IBOutlet weak var strictNodesLb: NSTextField! {
		didSet {
			strictNodesLb.stringValue = L10n.excludeNodesNever
		}
	}

	@IBOutlet weak var strictNodesSw: NSSwitch! {
		didSet {
			strictNodesSw.state = Settings.strictNodes ? .on : .off
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

	@IBOutlet weak var torConfRefBt: NSButton! {
		didSet {
			torConfRefBt.title = L10n.torConfReference
		}
	}

	@IBOutlet weak var torConfTf: NSTextField! {
		didSet {
			torConfTf.stringValue = Settings.advancedTorConf?.joined(separator: "\n") ?? ""
		}
	}

	@IBOutlet weak var torConfExplLb: NSTextField! {
		didSet {
			torConfExplLb.stringValue = L10n.settingsExplanation2
		}
	}

	@IBOutlet weak var box3: NSBox! {
		didSet {
			box3.title = L10n.maintenance
		}
	}

	@IBOutlet weak var clearCacheBt: NSButton! {
		didSet {
			clearCacheBt.title = L10n.clearTorCache
		}
	}


	override func viewDidAppear() {
		super.viewDidAppear()

		view.window?.title = L10n.settings

		statusChanged()

		NotificationCenter.default.addObserver(forName: .vpnStatusChanged, object: nil, queue: .main) { [weak self] _ in
			self?.statusChanged()
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
			alert.addButton(withTitle: L10n.cancel)

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

	@IBAction func showTorConfRef(_ sender: NSButton) {
		NSWorkspace.shared.open(SharedUtils.torConfUrl)
	}

	@IBAction func changeTorConf(_ sender: NSTextField) {
		Settings.advancedTorConf = sender.stringValue
			.components(separatedBy: .newlines)
			.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
	}

	@IBAction func clearCache(_ sender: NSButton) {
		SharedUtils.clearTorCache()

		let alert = NSAlert()
		alert.messageText = L10n.cleared

		alert.runModal()
	}


	// MARK: Private Methods
	
	private func statusChanged() {
		clearCacheBt.isEnabled = !VpnManager.shared.isConnected
	}
}

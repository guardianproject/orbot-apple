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
			infoLb.stringValue = NSLocalizedString("Settings will only take effect after restart.", comment: "")
		}
	}

	@IBOutlet weak var box1: NSBox! {
		didSet {
			box1.title = NSLocalizedString("Onion-only Mode", comment: "")
		}
	}

	@IBOutlet weak var onionOnlyLb: NSTextField! {
		didSet {
			onionOnlyLb.stringValue = String(format: NSLocalizedString("Disable %@ for non-onion traffic", comment: ""), Bundle.main.displayName)
		}
	}

	@IBOutlet weak var onionOnlySw: NSSwitch! {
		didSet {
			onionOnlySw.state = Settings.onionOnly ? .on : .off
		}
	}

	@IBOutlet weak var onionOnlyExplLb: NSTextField! {
		didSet {
			onionOnlyExplLb.stringValue = NSLocalizedString("ATTENTION: This may harm your anonymity and security!", comment: "")
		}
	}

	@IBOutlet weak var box2: NSBox! {
		didSet {
			box2.title = NSLocalizedString("Node Configuration", comment: "")
		}
	}

	@IBOutlet weak var entryNodesLb: NSTextField! {
		didSet {
			entryNodesLb.stringValue = NSLocalizedString("Entry Nodes", comment: "")
		}
	}

	@IBOutlet weak var entryNodesExplLb: NSTextField! {
		didSet {
			entryNodesExplLb.stringValue = NSLocalizedString("Only use these nodes as first hop. Ignored, when bridging is used.", comment: "")
		}
	}

	@IBOutlet weak var entryNodesTf: NSTextField! {
		didSet {
			entryNodesTf.stringValue = Settings.entryNodes ?? ""
		}
	}

	@IBOutlet weak var exitNodesLb: NSTextField! {
		didSet {
			exitNodesLb.stringValue = NSLocalizedString("Exit Nodes", comment: "")
		}
	}

	@IBOutlet weak var exitNodesExplLb: NSTextField! {
		didSet {
			exitNodesExplLb.stringValue = NSLocalizedString("Only use these nodes to connect outside the Tor network. You will degrade functionality if you list too few!", comment: "")
		}
	}

	@IBOutlet weak var exitNodesTf: NSTextField! {
		didSet {
			exitNodesTf.stringValue = Settings.exitNodes ?? ""
		}
	}

	@IBOutlet weak var excludeNodesLb: NSTextField! {
		didSet {
			excludeNodesLb.stringValue = NSLocalizedString("Exclude Nodes", comment: "")
		}
	}

	@IBOutlet weak var excludeNodesExplLb: NSTextField! {
		didSet {
			excludeNodesExplLb.stringValue = NSLocalizedString("Do not use these nodes. Overrides entry and exit node list. May still be used for management purposes.", comment: "")
		}
	}

	@IBOutlet weak var excludeNodesTf: NSTextField! {
		didSet {
			excludeNodesTf.stringValue = Settings.excludeNodes ?? ""
		}
	}

	@IBOutlet weak var strictNodesLb: NSTextField! {
		didSet {
			strictNodesLb.stringValue = NSLocalizedString("Also don't use excluded nodes for network management", comment: "")
		}
	}

	@IBOutlet weak var strictNodesSw: NSSwitch! {
		didSet {
			strictNodesSw.state = Settings.strictNodes ? .on : .off
		}
	}

	@IBOutlet weak var nodesExplLb: NSTextField! {
		didSet {
			nodesExplLb.stringValue = NSLocalizedString("Comma-separated lists of:", comment: "") + "\n"
			+ String(format: NSLocalizedString("%1$@ node fingerprints, e.g. \"%2$@\"", comment: ""), "\u{2022}", "ABCD1234CDEF5678ABCD1234CDEF5678ABCD1234") + "\n"
		 + String(format: NSLocalizedString("%1$@ 2-letter country codes in braces, e.g. \"%2$@\"", comment: ""), "\u{2022}", "{cc}") + "\n"
		 + String(format: NSLocalizedString("%1$@ IP address patterns, e.g. \"%2$@\"", comment: ""), "\u{2022}", "255.254.0.0/8") + "\n"
		}
	}

	@IBOutlet weak var box3: NSBox! {
		didSet {
			box3.title = NSLocalizedString("Advanced Tor Configuration", comment: "")
		}
	}

	@IBOutlet weak var torConfRefBt: NSButton! {
		didSet {
			torConfRefBt.title = NSLocalizedString("Tor Configuration Reference", comment: "")
		}
	}

	@IBOutlet weak var torConfTf: NSTextField! {
		didSet {
			torConfTf.stringValue = Settings.advancedTorConf?.joined(separator: "\n") ?? ""
		}
	}

	@IBOutlet weak var torConfExplLb: NSTextField! {
		didSet {
			torConfExplLb.stringValue = String(format: NSLocalizedString("%1$@ Options need 2 leading minuses: %2$@", comment: ""), "\u{2022}", "--Option") + "\n"
			+ String(format: NSLocalizedString("%@ Arguments to an option need to be in a new line.", comment: ""), "\u{2022}") + "\n"
		 + String(format: NSLocalizedString("%1$@ Some options might get overwritten by %2$@.", comment: ""), "\u{2022}", Bundle.main.displayName)
		}
	}


	// MARK: Actions

	@IBAction func changeOnionOnly(_ sender: NSSwitch) {
		if sender.state == .on {
			let message = NSLocalizedString("ATTENTION: This may harm your anonymity and security!", comment: "")
			+ "\n\n"
			+ NSLocalizedString("Only traffic to onion services (to domains ending in \".onion\") will be routed over Tor.", comment: "")
			+ "\n\n"
			+ NSLocalizedString("Traffic to all other domains will be routed through your normal Internet connection.", comment: "")
			+ "\n\n"
			+ NSLocalizedString("If these onion services aren't configured correctly, you will leak information to your Internet Service Provider and anybody else listening on that traffic!", comment: "")

			let alert = NSAlert()
			alert.messageText = NSLocalizedString("Warning", comment: "")
			alert.informativeText = message
			alert.addButton(withTitle: NSLocalizedString("Activate", comment: ""))
			alert.addButton(withTitle: NSLocalizedString("Cancel", bundle: .iPtProxyUI, comment: "#bc-ignore!"))

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
				VpnManager.shared.disconnect()
			}
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		title = NSLocalizedString("Settings", comment: "")
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
		NSWorkspace.shared.open(URL(string: "https://2019.www.torproject.org/docs/tor-manual.html")!)
	}

	@IBAction func changeTorConf(_ sender: NSTextField) {
		Settings.advancedTorConf = sender.stringValue
			.components(separatedBy: .newlines)
			.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
	}
}

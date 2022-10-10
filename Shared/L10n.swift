//
//  L10n.swift
//  Orbot
//
//  Created by Benjamin Erhart on 30.09.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import Foundation

class L10n {

	public static var settings: String {
		NSLocalizedString("Settings", comment: "")
	}

	public static var newCircuits: String {
		NSLocalizedString("Build new Circuits", comment: "")
	}

	public static var version: String {
		String(format: NSLocalizedString("Version %@, Build %@", comment: ""),
			   Bundle.main.version, Bundle.main.build)
	}

	public static var log: String {
		NSLocalizedString("Log", comment: "")
	}

	public static var circuits: String {
		NSLocalizedString("Circuits", comment: "")
	}

	public static var authCookies: String {
		NSLocalizedString("Auth Cookies", comment: "")
	}

	public static var bridgeConf: String {
		NSLocalizedString("Bridge Configuration", bundle: Bundle.iPtProxyUI, comment: "#bc-ignore!")
	}

	public static var error: String {
		NSLocalizedString("Error", bundle: Bundle.iPtProxyUI, comment: "#bc-ignore!")
	}

	public static var add: String {
		NSLocalizedString("Add", comment: "")
	}

	public static var editAuthCookie: String {
		NSLocalizedString("Edit v3 Onion Service Auth Cookie", comment: "")
	}

	public static var edit: String {
		NSLocalizedString("Edit", comment: "")
	}

	public static var addAuthCookie: String {
		NSLocalizedString("Add v3 Onion Service Auth Cookie", comment: "")
	}

	public static var delete: String {
		NSLocalizedString("Delete", comment: "")
	}

	public static var key: String {
		NSLocalizedString("Key", comment: "")
	}

	public static var cancel: String {
		NSLocalizedString("Cancel", bundle: .iPtProxyUI, comment: "#bc-ignore!")
	}

	public static var general: String {
		NSLocalizedString("General", comment: "")
	}

	public static var settingsExplanation1: String {
		NSLocalizedString("Comma-separated lists of:", comment: "") + "\n"
		+ String(format: NSLocalizedString("%1$@ node fingerprints, e.g. \"%2$@\"", comment: ""), "\u{2022}", "ABCD1234CDEF5678ABCD1234CDEF5678ABCD1234") + "\n"
		+ String(format: NSLocalizedString("%1$@ 2-letter country codes in braces, e.g. \"%2$@\"", comment: ""), "\u{2022}", "{cc}") + "\n"
		+ String(format: NSLocalizedString("%1$@ IP address patterns, e.g. \"%2$@\"", comment: ""), "\u{2022}", "255.254.0.0/8") + "\n"
	}

	public static var settingsExplanation2: String {
		String(format: NSLocalizedString("%1$@ Options need 2 leading minuses: %2$@", comment: ""), "\u{2022}", "--Option") + "\n"
			+ String(format: NSLocalizedString("%@ Arguments to an option need to be in a new line.", comment: ""), "\u{2022}") + "\n"
			+ String(format: NSLocalizedString("%1$@ Some options might get overwritten by %2$@.", comment: ""), "\u{2022}", Bundle.main.displayName)
	}

	public static var settingsExplanation3: String {
		NSLocalizedString("ATTENTION: This may harm your anonymity and security!", comment: "")
		+ "\n\n"
		+ NSLocalizedString("Only traffic to onion services (to domains ending in \".onion\") will be routed over Tor.", comment: "")
		+ "\n\n"
		+ NSLocalizedString("Traffic to all other domains will be routed through your normal Internet connection.", comment: "")
		+ "\n\n"
		+ NSLocalizedString("If these onion services aren't configured correctly, you will leak information to your Internet Service Provider and anybody else listening on that traffic!", comment: "")
	}

	public static var settingsEfectAfterRestart: String {
		NSLocalizedString("Most settings will only take effect after restart.", comment: "")
	}

	public static var automaticRestart: String {
		NSLocalizedString("Automatic Restart", comment: "")
	}

	public static var automaticallyRestartOnError: String {
		NSLocalizedString("Automatically Restart on Error", comment: "")
	}

	public static var onionOnlyMode: String {
		NSLocalizedString("Onion-only Mode", comment: "")
	}

	public static var attentionAnonymity:String {
		NSLocalizedString("ATTENTION: This may harm your anonymity and security!", comment: "")
	}

	public static var disableForNonOnionTraffic: String {
		String(format: NSLocalizedString("Disable %@ for non-onion traffic", comment: ""), Bundle.main.displayName)
	}

	public static var warning: String {
		NSLocalizedString("Warning", comment: "")
	}

	public static var activate: String {
		NSLocalizedString("Activate", comment: "")
	}

	public static var nodeConfiguration: String {
		NSLocalizedString("Node Configuration", comment: "")
	}

	public static var entryNodes: String {
		NSLocalizedString("Entry Nodes", comment: "")
	}

	public static var entryNodesExplanation: String {
		NSLocalizedString("Only use these nodes as first hop. Ignored, when bridging is used.", comment: "")
	}

	public static var exitNodes: String {
		NSLocalizedString("Exit Nodes", comment: "")
	}

	public static var exitNodesExplanation: String {
		NSLocalizedString("Only use these nodes to connect outside the Tor network. You will degrade functionality if you list too few!", comment: "")
	}

	public static var excludeNodes: String {
		NSLocalizedString("Exclude Nodes", comment: "")
	}

	public static var excludeNodesExplanation: String {
		NSLocalizedString("Do not use these nodes. Overrides entry and exit node list. May still be used for management purposes.", comment: "")
	}

	public static var excludeNodesNever: String {
		NSLocalizedString("Also don't use excluded nodes for network management", comment: "")
	}

	public static var advancedTorConf: String {
		NSLocalizedString("Advanced Tor Configuration", comment: "")
	}

	public static var torConfReference: String {
		NSLocalizedString("Tor Configuration Reference", comment: "")
	}

	public static var maintenance: String {
		NSLocalizedString("Maintenance", comment: "")
	}

	public static var clearTorCache: String {
		NSLocalizedString("Clear Tor Cache", comment: "")
	}

	public static var cleared: String {
		NSLocalizedString("Cleared!", comment: "")
	}
}

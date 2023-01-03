//
//  L10n.swift
//  Orbot
//
//  Created by Benjamin Erhart on 30.09.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import Foundation

class L10n {

	static var settings: String {
		NSLocalizedString("Settings", comment: "")
	}

	static var newCircuits: String {
		NSLocalizedString("Build new Circuits", comment: "")
	}

	static var snowflakeProxyStarted: String {
		"Snowflake Proxy: started (%@ people helped)"
	}

	static var snowflakeProxyStopped: String {
		"Snowflake Proxy: stopped (%@ people helped)"
	}

	static var version: String {
		String(format: NSLocalizedString("Version %@, Build %@", comment: ""),
			   Bundle.main.version, Bundle.main.build)
	}

	static var log: String {
		NSLocalizedString("Log", comment: "")
	}

	static var bridges: String {
		NSLocalizedString("Bridges", comment: "")
	}

	static var circuits: String {
		NSLocalizedString("Circuits", comment: "")
	}

	static var authCookies: String {
		NSLocalizedString("Auth Cookies", comment: "")
	}

	static var bridgeConf: String {
		NSLocalizedString("Bridge Configuration", bundle: Bundle.iPtProxyUI, comment: "#bc-ignore!")
	}

	static var error: String {
		NSLocalizedString("Error", bundle: Bundle.iPtProxyUI, comment: "#bc-ignore!")
	}

	static var add: String {
		NSLocalizedString("Add", comment: "")
	}

	static var editAuthCookie: String {
		NSLocalizedString("Edit v3 Onion Service Auth Cookie", comment: "")
	}

	static var edit: String {
		NSLocalizedString("Edit", comment: "")
	}

	static var addAuthCookie: String {
		NSLocalizedString("Add v3 Onion Service Auth Cookie", comment: "")
	}

	static var delete: String {
		NSLocalizedString("Delete", comment: "")
	}

	static var key: String {
		NSLocalizedString("Key", comment: "")
	}

	static var cancel: String {
		NSLocalizedString("Cancel", bundle: .iPtProxyUI, comment: "#bc-ignore!")
	}

	static var general: String {
		NSLocalizedString("General", comment: "")
	}

	static var settingsExplanation1: String {
		NSLocalizedString("Comma-separated lists of:", comment: "") + "\n"
		+ String(format: NSLocalizedString("%1$@ node fingerprints, e.g. \"%2$@\"", comment: ""), "\u{2022}", "ABCD1234CDEF5678ABCD1234CDEF5678ABCD1234") + "\n"
		+ String(format: NSLocalizedString("%1$@ 2-letter country codes in braces, e.g. \"%2$@\"", comment: ""), "\u{2022}", "{cc}") + "\n"
		+ String(format: NSLocalizedString("%1$@ IP address patterns, e.g. \"%2$@\"", comment: ""), "\u{2022}", "255.254.0.0/8") + "\n"
	}

	static var settingsExplanation2: String {
		String(format: NSLocalizedString("%1$@ Options need 2 leading minuses: %2$@", comment: ""), "\u{2022}", "--Option") + "\n"
		+ String(format: NSLocalizedString("%@ Arguments to an option need to be in a new line.", comment: ""), "\u{2022}") + "\n"
		+ String(format: NSLocalizedString("%1$@ Some options might get overwritten by %2$@.", comment: ""), "\u{2022}", Bundle.main.displayName) + "\n"
		+ String(format: NSLocalizedString("%1$@ These settings will only take effect after restart.", comment: ""), "\u{2022}")
	}

	static var settingsExplanation3: String {
		NSLocalizedString("ATTENTION: This may harm your anonymity and security!", comment: "")
		+ "\n\n"
		+ NSLocalizedString("Only traffic to onion services (to domains ending in \".onion\") will be routed over Tor.", comment: "")
		+ "\n\n"
		+ NSLocalizedString("Traffic to all other domains will be routed through your normal Internet connection.", comment: "")
		+ "\n\n"
		+ NSLocalizedString("If these onion services aren't configured correctly, you will leak information to your Internet Service Provider and anybody else listening on that traffic!", comment: "")
	}

	static var settingsEfectAfterRestart: String {
		NSLocalizedString("Most settings will only take effect after restart.", comment: "")
	}

	static var automaticRestart: String {
		NSLocalizedString("Automatic Restart", comment: "")
	}

	static var automaticallyRestartOnError: String {
		NSLocalizedString("Automatically Restart on Error", comment: "")
	}

	static var onionOnlyMode: String {
		NSLocalizedString("Onion-only Mode", comment: "")
	}

	static var attentionAnonymity:String {
		NSLocalizedString("ATTENTION: This may harm your anonymity and security!", comment: "")
	}

	static var disableForNonOnionTraffic: String {
		String(format: NSLocalizedString("Disable %@ for non-onion traffic",  comment: "macOS menu item"), Bundle.main.displayName)
	}

	static var warning: String {
		NSLocalizedString("Warning", comment: "")
	}

	static var activate: String {
		NSLocalizedString("Activate", comment: "")
	}

	static var nodeConfiguration: String {
		NSLocalizedString("Node Configuration", comment: "")
	}

	static var entryNodes: String {
		NSLocalizedString("Entry Nodes", comment: "")
	}

	static var entryNodesExplanation: String {
		NSLocalizedString("Only use these nodes as first hop. Ignored, when bridging is used.", comment: "")
	}

	static var exitNodes: String {
		NSLocalizedString("Exit Nodes", comment: "")
	}

	static var exitNodesExplanation: String {
		NSLocalizedString("Only use these nodes to connect outside the Tor network. You will degrade functionality if you list too few!", comment: "")
	}

	static var exitNodeCountries: String {
		NSLocalizedString("Exit Node Countries", comment: "")
	}

	static var excludeNodes: String {
		NSLocalizedString("Exclude Nodes", comment: "")
	}

	static var excludeNodesExplanation: String {
		NSLocalizedString("Do not use these nodes. Overrides entry and exit node list. May still be used for management purposes.", comment: "")
	}

	static var excludeNodesNever: String {
		NSLocalizedString("Also don't use excluded nodes for network management", comment: "")
	}

	static var advancedTorConf: String {
		NSLocalizedString("Advanced Tor Configuration", comment: "")
	}

	static var torConfReference: String {
		NSLocalizedString("Tor Configuration Reference", comment: "")
	}

	static var maintenance: String {
		NSLocalizedString("Maintenance", comment: "")
	}

	static var clearTorCache: String {
		NSLocalizedString("Clear Tor Cache", comment: "")
	}

	static var cleared: String {
		NSLocalizedString("Cleared!", comment: "")
	}

	static var expert: String {
		NSLocalizedString("Expert", comment: "")
	}

	static var smartConnectTimeout: String {
		NSLocalizedString("Smart Connect Timeout (s)", comment: "")
	}

	static let menu: [String: () -> String] = [
		"Orbot" : { Bundle.main.displayName },
		"About Orbot": { String(format: NSLocalizedString("About %@",  comment: "macOS menu item"), Bundle.main.displayName) },
		"Preferences…": { NSLocalizedString("Preferences…", comment: "macOS menu item") },
		"Services" : { NSLocalizedString("Services", comment: "macOS menu item") },
		"Hide Orbot": { String(format: NSLocalizedString("Hide %@",  comment: "macOS menu item"), Bundle.main.displayName) },
		"Hide Others" : { NSLocalizedString("Hide Others", comment: "macOS menu item") },
		"Show All" : { NSLocalizedString("Show All", comment: "macOS menu item") },
		"Quit Orbot": { String(format: NSLocalizedString("Quit %@",  comment: "macOS menu item"), Bundle.main.displayName) },
		"File" : { NSLocalizedString("File", comment: "macOS menu item") },
		"Close" : { NSLocalizedString("Close", comment: "macOS menu item") },
		"Edit" : { NSLocalizedString("Edit", comment: "macOS menu item") },
		"Undo" : { NSLocalizedString("Undo", comment: "macOS menu item") },
		"Redo" : { NSLocalizedString("Redo", comment: "macOS menu item") },
		"Cut" : { NSLocalizedString("Cut", comment: "macOS menu item") },
		"Copy" : { NSLocalizedString("Copy", comment: "macOS menu item") },
		"Paste" : { NSLocalizedString("Paste", comment: "macOS menu item") },
		"Paste and Match Style" : { NSLocalizedString("Paste and Match Style", comment: "macOS menu item") },
		"Delete" : { NSLocalizedString("Delete", comment: "macOS menu item") },
		"Select All" : { NSLocalizedString("Select All", comment: "macOS menu item") },
		"Find" : { NSLocalizedString("Find", comment: "macOS menu item") },
		"Find…" : { NSLocalizedString("Find…", comment: "macOS menu item") },
		"Find and Replace…" : { NSLocalizedString("Find and Replace…", comment: "macOS menu item") },
		"Find Next" : { NSLocalizedString("Find Next", comment: "macOS menu item") },
		"Find Previous" : { NSLocalizedString("Find Previous", comment: "macOS menu item") },
		"Use Selection for Find" : { NSLocalizedString("Use Selection for Find", comment: "macOS menu item") },
		"Jump to Selection" : { NSLocalizedString("Jump to Selection", comment: "macOS menu item") },
		"Transformations" : { NSLocalizedString("Transformations", comment: "macOS menu item") },
		"Make Upper Case" : { NSLocalizedString("Make Upper Case", comment: "macOS menu item") },
		"Make Lower Case" : { NSLocalizedString("Make Lower Case", comment: "macOS menu item") },
		"Capitalize" : { NSLocalizedString("Capitalize", comment: "macOS menu item") },
		"Speech" : { NSLocalizedString("Speech", comment: "macOS menu item") },
		"Start Speaking" : { NSLocalizedString("Start Speaking", comment: "macOS menu item") },
		"Stop Speaking" : { NSLocalizedString("Stop Speaking", comment: "macOS menu item") },
		"View" : { NSLocalizedString("View", comment: "macOS menu item") },
		"Show Toolbar" : { NSLocalizedString("Show Toolbar", comment: "macOS menu item") },
		"Customize Toolbar…" : { NSLocalizedString("Customize Toolbar…", comment: "macOS menu item") },
		"Enter Full Screen" : { NSLocalizedString("Enter Full Screen", comment: "macOS menu item") },
		"Window" : { NSLocalizedString("Window", comment: "macOS menu item") },
		"Minimize" : { NSLocalizedString("Minimize", comment: "macOS menu item") },
		"Zoom" : { NSLocalizedString("Zoom", comment: "macOS menu item") },
		"Bring All to Front" : { NSLocalizedString("Bring All to Front", comment: "macOS menu item") },
		"Log" : { NSLocalizedString("Log", comment: "macOS menu item") },
		"Help" : { NSLocalizedString("Help", comment: "macOS menu item") },
		"Orbot Help": { String(format: NSLocalizedString("%@ Help",  comment: "macOS menu item"), Bundle.main.displayName) },
	]
}

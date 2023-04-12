#!/usr/bin/env swift

// Prepares the configuration to do a "Developer ID" release, which
// can be distributed outside the app store.
//
// RUn with "-u" or "--undo" to undo the changes!

import Foundation


// MARK: Config

let entitlementFiles = [resolve("Orbot Mac/Orbot_Mac.entitlements"), resolve("TorVPN Mac/TorVPN_Mac.entitlements")]

let neKey = "com.apple.developer.networking.networkextension"

let entitlementReplacements = [
	"packet-tunnel-provider": "packet-tunnel-provider-systemextension",
	"app-proxy-provider": "app-proxy-provider-systemextension",
	"content-filter-provider": "content-filter-provider-systemextension",
	"dns-proxy": "dns-proxy-systemextension",
]


let configFile = resolve("Shared/Config.xcconfig")

let configReplacements = [
	"CODE_SIGN_IDENTITY[config=Release]": [
		"devid": "Developer ID Application: The Tor Project, Inc (MADPSAYN6T)",
		"appstore": "Apple Distribution: The Tor Project, Inc (MADPSAYN6T)",
	],
	"APP_PROVISIONING_PROFILE_SPECIFIER_MAC[config=Release]": [
		"devid": "Orbot macOS DevID 2023",
		"appstore": "Orbot macOS Dist 2022",
	],
	"EXT_PROVISIONING_PROFILE_SPECIFIER_MAC[config=Release]": [
		"devid": "Orbot macOS Ext DevID 2023",
		"appstore": "Orbot macOS Ext Dist 2022",
	],
]



// MARK: Helper Methods

func resolve(_ path: String) -> URL {
	let script = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()

	if script.path.hasPrefix("/") {
		return URL(fileURLWithPath: path, relativeTo: script)
	}

	let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
	let base = URL(fileURLWithPath: script.path, relativeTo: cwd)

	return URL(fileURLWithPath: path, relativeTo: base)
}


// MARK: Classes



// MARK: Main

let args = CommandLine.arguments

let undo = args.count > 1 && (args[1] == "--undo" || args[1] == "-u")


for file in entitlementFiles {
	let content = NSMutableDictionary(contentsOf: file)

	guard let neEntitlements = content?[neKey] as? [String] else {
		continue
	}

	let replacement = NSMutableArray()

	for e in neEntitlements {
		let r = (undo ? entitlementReplacements.first(where: { $0.value == e })?.key : entitlementReplacements[e]) ?? e

		replacement.add(r)
	}

	content?[neKey] = replacement

	content?.write(to: file, atomically: true)
}

do {
	var config = try String(contentsOf: configFile)

	for r in configReplacements {
		guard let value = r.value[undo ? "appstore" : "devid"] else {
			continue
		}

		let key = r.key.replacingOccurrences(of: "[", with: "\\[").replacingOccurrences(of: "]", with: "\\]")

		let regex = try NSRegularExpression(pattern: "^\(key)\\s*=.*$", options: .anchorsMatchLines)

		config = regex.stringByReplacingMatches(in: config, options: [],
												range: NSRange(location: 0, length: config.count),
												withTemplate: "\(r.key) = \(value)")
	}

	try config.write(to: configFile, atomically: true, encoding: .utf8)
}
catch {
	print(error)
	exit(1)
}

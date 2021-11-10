//
//  FileManager+Helpers.swift
//  Orbot
//
//  Created by Benjamin Erhart on 20.05.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import Foundation

extension FileManager {

	var groupFolder: URL? {
		return containerURL(forSecurityApplicationGroupIdentifier: Config.groupId)
	}

	var vpnLogFile: URL? {
		return groupFolder?.appendingPathComponent("log")
	}

	var torLogFile: URL? {
		return groupFolder?.appendingPathComponent("tor.log")
	}

	var leafLogFile: URL? {
		return groupFolder?.appendingPathComponent("leaf.log")
	}

	var leafConfFile: URL? {
		return groupFolder?.appendingPathComponent("leaf.conf")
	}

	var leafConfTemplateFile: URL? {
		return Bundle.main.url(forResource: "template", withExtension: "conf")
	}

	var builtInObfs4BridgesFile: URL? {
		return Bundle.main.url(forResource: "obfs4-bridges", withExtension: "plist")
	}

	var customObfs4BridgesFile: URL? {
		return groupFolder?.appendingPathComponent("custom-bridges.plist")
	}

	var leafConfTemplate: String? {
		if let templateFile = leafConfTemplateFile {
			return try? String(contentsOf: templateFile)
		}

		return nil
	}

	var builtInObfs4Bridges: [String] {
		guard let file = builtInObfs4BridgesFile else {
			return []
		}

		return NSArray(contentsOf: file) as? [String] ?? []
	}

	var customObfs4Bridges: [String]? {
		get {
			guard let file = customObfs4BridgesFile else {
				return nil
			}

			return NSArray(contentsOf: file) as? [String]
		}

		set {
			guard let file = customObfs4BridgesFile
			else {
				return
			}

			if let newValue = newValue {
				(newValue as NSArray).write(to: file, atomically: true)
			}
			else {
				try? removeItem(at: file)
			}
		}
	}

}

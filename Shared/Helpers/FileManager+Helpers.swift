//
//  FileManager+Helpers.swift
//  Orbot
//
//  Created by Benjamin Erhart on 20.05.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import Foundation

extension FileManager {

	var groupDir: URL? {
		containerURL(forSecurityApplicationGroupIdentifier: Config.groupId)
	}

	var vpnLogFile: URL? {
		groupDir?.appendingPathComponent("log")
	}

	var torLogFile: URL? {
		groupDir?.appendingPathComponent("tor.log")
	}

	var leafLogFile: URL? {
		groupDir?.appendingPathComponent("leaf.log")
	}

	var leafConfFile: URL? {
		groupDir?.appendingPathComponent("leaf.conf")
	}

	var leafConfTemplateFile: URL? {
		Bundle.main.url(forResource: "template", withExtension: "conf")
	}

	var leafConfOnionOnlyTemplateFile: URL? {
		Bundle.main.url(forResource: "template-onion-only", withExtension: "conf")
	}

	var leafConfBypassTemplateFile: URL? {
		Bundle.main.url(forResource: "template-bypass", withExtension: "conf")
	}

	var wsLogFile: URL? {
		groupDir?.appendingPathComponent("ws.log")
	}

	var torDir: URL? {
		guard let url = groupDir?.appendingPathComponent("tor") else {
			return nil
		}

		try? createDirectory(at: url, withIntermediateDirectories: true)

		return url
	}

	var torAuthDir: URL? {
		guard let url = torDir?.appendingPathComponent("auth") else {
			return nil
		}

		try? createDirectory(at: url, withIntermediateDirectories: true)

		return url
	}

	var ptDir: URL? {
		groupDir?.appendingPathComponent("pt_state")
	}

	var sfpLogFile: URL? {
		groupDir?.appendingPathComponent("sfp.log")
	}

	var artiStateDir: URL? {
		groupDir?.appendingPathComponent("arti-state")
	}

	var artiCacheDir: URL? {
		groupDir?.appendingPathComponent("arti-cache")
	}
}

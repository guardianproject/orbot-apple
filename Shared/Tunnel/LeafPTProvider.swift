//
//  LeafPTProvider.swift
//  TorVPN
//
//  Created by Benjamin Erhart on 16.09.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import NetworkExtension

/**
 https://github.com/eycorsican/leaf.git
 */
class LeafPTProvider: BasePTProvider {

	private static let leafId: UInt16 = 666

	override func startTun2Socks(socksAddr: String?, dnsAddr: String?) {
		let tunFd = tunnelFd != nil ? String(tunnelFd!) : nil
		let socks = socksAddr?.split(separator: ":")
		let dns = dnsAddr?.split(separator: ":")

		// Reset log file.
		if let url = FileManager.default.leafLogFile {
			try? "".write(to: url, atomically: true, encoding: .utf8)
		}

		let fm = FileManager.default
		var conf = ""

		if let file = Settings.onionOnly ? fm.leafConfOnionOnlyTemplateFile : fm.leafConfTemplateFile  {
			conf = (try? String(contentsOf: file)) ?? ""
		}

		conf = conf
			.replacingOccurrences(of: "{{leafLogFile}}", with: FileManager.default.leafLogFile?.path ?? "")
			.replacingOccurrences(of: "{{tunFd}}", with: tunFd ?? "")
			.replacingOccurrences(of: "{{dnsHost}}", with: dns?.first ?? "")
			.replacingOccurrences(of: "{{dnsPort}}", with: dns?.last ?? "")
			.replacingOccurrences(of: "{{socksHost}}", with: socks?.first ?? "")
			.replacingOccurrences(of: "{{socksPort}}", with: socks?.last ?? "")

		let file = FileManager.default.leafConfFile

		try! conf.write(to: file!, atomically: true, encoding: .utf8)

		setenv("LOG_NO_COLOR", "true", 1)

		DispatchQueue.global(qos: .userInteractive).async {
			leaf_run(LeafPTProvider.leafId, file?.path)
		}
	}

	override func stopTun2Socks() {
		leaf_shutdown(LeafPTProvider.leafId)
	}
}

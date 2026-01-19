//
//  LeafPTProvider.swift
//  TorVPN
//
//  Created by Benjamin Erhart on 16.09.21.
//  Copyright © 2020 - 2026 Guardian Project. All rights reserved.
//

import NetworkExtension

/**
 https://github.com/eycorsican/leaf.git
 */
class LeafPTProvider: BasePTProvider {

	private static let leafId: UInt16 = 666

	override func startTun2Socks(socksAddr: String?, dnsAddr: String?) throws {
		guard let tunFd = tunnelFd else {
			throw Errors.tunnelFdNotFound
		}

		guard let socks = socksAddr?.split(separator: ":"), socks.count == 2 else {
			throw Errors.socksPortUnparsable
		}

		guard let dns = dnsAddr?.split(separator: ":"), dns.count == 2 else {
			throw Errors.dnsPortUnparsable
		}

		let bypassPort = Settings.bypassPort != nil ? String(Settings.bypassPort!) : nil


		let fm = FileManager.default

		// Reset log file.
		fm.leafLogFile?.truncate()

		var conf: String

		if Settings.onionOnly {
			conf = fm.leafConfOnionOnlyTemplateFile?.contents ?? ""
		}
		else {
			if bypassPort != nil {
				conf = fm.leafConfBypassTemplateFile?.contents ?? ""
			}
			else {
				conf = fm.leafConfTemplateFile?.contents ?? ""
			}
		}

		conf = conf
			.replacingOccurrences(of: "{{leafLogFile}}", with: fm.leafLogFile?.path ?? "")
			.replacingOccurrences(of: "{{tunFd}}", with: String(tunFd))
			.replacingOccurrences(of: "{{bypassPort}}", with: bypassPort ?? "")
			.replacingOccurrences(of: "{{dnsHost}}", with: dns.first!)
			.replacingOccurrences(of: "{{dnsPort}}", with: dns.last!)
			.replacingOccurrences(of: "{{socksHost}}", with: socks.first!)
			.replacingOccurrences(of: "{{socksPort}}", with: socks.last!)

		let file = fm.leafConfFile

		try conf.write(to: file!, atomically: true, encoding: .utf8)

		setenv("LOG_NO_COLOR", "true", 1)

		DispatchQueue.global(qos: .userInteractive).async {
			leaf_run(LeafPTProvider.leafId, file?.path)
		}
	}

	override func stopTun2Socks() {
		leaf_shutdown(LeafPTProvider.leafId)
	}
}

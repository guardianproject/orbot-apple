//
//  ChromiumHsts.swift
//  Orbot
//
//  Created by Benjamin Erhart on 11.04.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import UIKit

class ChromiumHsts: BlockerSource {

	let sourceUrl = URL(string: "https://chromium.googlesource.com/chromium/src/net/+/master/http/transport_security_state_static.json?format=TEXT")!

	override var blockFile: URL? {
		FileManager.default.groupDir?.appendingPathComponent("chromium_hsts.json")
	}

	override var count: Int {
		blocklist.first?.trigger.ifDomain?.count ?? 0
	}

	override func update(_ completion: @escaping (_ error: Error?) -> Void) {
		let task = URLSession.shared.dataTask(with: URLRequest(url: sourceUrl)) { [weak self] data, response, error in

		//	print("data=\(String(describing: data)), response=\(String(describing: response)), error=\(String(describing: error))")

			if let error = error {
				return completion(error)
			}

			guard let data = data else {
				return completion(BlockerError.noData)
			}

			guard let data = Data(base64Encoded: data) else {
				return completion(BlockerError.invalidBase64)
			}

			let hsts: Hsts

			do {
				hsts = try Self.decoder.decode(Hsts.self, from: data)
			}
			catch {
				return completion(error)
			}


			var item = BlockItem(trigger: BlockTrigger(urlFilter: ".*", ifDomain: []), action: BlockAction(type: .makeHttps))

			for entry in hsts.entries {
//				print(entry)

				if entry.mode == .forceHttps {
					let domain = (entry.includeSubdomains ?? false ? "*" : "") + entry.name

					item.trigger.ifDomain?.append(domain)
				}
			}

			self?.blocklist = [item]

			completion(nil)
		}
		task.resume()
	}
}

/**
The documentation is taken from the top of the source file, which contains this. Base64 decode it to find this and adapt, if changed!

 The top-level element is a dictionary with two keys: "pinsets" maps details
 of certificate pinning to a name and "entries" contains the HSTS details for
 each host.
 */
struct Hsts: Codable {

	var pinsets: [Pinset]

	var entries: [Entry]
}

/**
 For a given pinset, a certificate is accepted if at least one of the
 `static_spki_hashes` SPKIs is found in the chain and none of the
 `bad_static_spki_hashes` SPKIs are. SPKIs are specified as names, which must
 match up with the file of certificates.
 */
struct Pinset: Codable {

	/**
	 The name of the pinset.
	 */
	var name: String

	/**
	 The set of allowed SPKIs hashes.
	 */
	var staticSpkiHashes: [String]

	/**
	 The set of forbidden SPKIs hashes.
	 */
	var badStaticSpkiHashes: [String]?

	/**
	 The URI to send violation reports to; reports will be in the format defined in RFC 7469.
	 */
	var reportUri: String?
}

struct Entry: Codable {

	enum Policy: String, Codable, CustomStringConvertible {

		/**
		 Test domains
		 */
		case test = "test"

		/**
		 Google-owned sites.
		 */
		case google = "google"

		/**
		 Entries without `includeSubdomains` or with HPKP/Expect-CT.
		 */
		case custom = "custom"

		/**
		 Bulk entries preloaded before Chrome 50.
		 */
		case bulkLegacy = "bulk-legacy"

		/**
		 Bulk entries with max-age >= 18 weeks (Chrome 50-63).
		 */
		case bulk18Weeks = "bulk-18-weeks"

		/**
		 Bulk entries with max-age >= 1 year (after Chrome 63).
		 */
		case bulk1Year = "bulk-1-year"

		/**
		 Public suffixes (e.g. TLDs or other public suffix list entries) preloaded at the owner's request.
		 */
		case publicSuffix = "public-suffix"

		/**
		 Domains under a public suffix that have been preloaded at the request of the the public suffix owner (e.g. the registry for the TLD).
		 */
		case publicSuffixRequested = "public-suffix-requested"

		var description: String {
			return rawValue
		}
	}

	enum Mode: String, Codable, CustomStringConvertible {

		/**
		 If covered names should require HTTPS.
		 */
		case forceHttps = "force-https"

		var description: String {
			return rawValue
		}
	}

	/**
	 The DNS name of the host in question.
	 */
	var name: String

	/**
	 the policy under which the domain is part of the preload list. This field is used for list maintenance.
	 */
	var policy: Policy?

	/**
	 For backwards compatibility, this means:

	 - If mode == "force-https", then apply force-https to subdomains.
	 - If "pins" is set, then apply the pinset to subdomains.
	 */
	var includeSubdomains: Bool?

	/**
	 Whether subdomains of `name` are also covered for pinning.
	 As noted above, `include_subdomains` also has the same effect on pinning.
	 */
	var includeSubdomainsForPinning: Bool?

	/**
	 "force-https" if covered names should require HTTPS.
	 */
	var mode: Mode?

	/**
	 The `name` member of an object in `pinsets`.
	 */
	var pins: String?

	/**
	 true if the site expects Certificate Transparency information to be present on requests to `name`.
	 */
	var expectCt: Bool?

	/**
	 If `expect_ct` is true, the URI to which reports should be sent when valid Certificate Transparency information is not present.
	 */
	var expectCtReportUri: String?
}

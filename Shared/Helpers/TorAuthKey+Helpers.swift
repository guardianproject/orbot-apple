//
//  TorAuthKey+Helpers.swift
//  Orbot
//
//  Created by Benjamin Erhart on 24.08.22.
//  Copyright © 2020 - 2026 Guardian Project. All rights reserved.
//

import Tor

extension TorAuthKey {

	convenience init?(private key: String, forDomain rawUrl: String) {

		var urlc = URLComponents(string: rawUrl)

		// If you just enter some alhpanumerics, it ends up as the path,
		// but just to be sure, we copy from everywhere else, too.
		if urlc?.host?.isEmpty ?? true {
			let path = urlc?.path.isEmpty ?? true ? nil : urlc?.path
			var host = path ?? urlc?.query ?? urlc?.fragment ?? urlc?.scheme ?? urlc?.user
			host = host ?? urlc?.password
			urlc?.host = host
		}

		guard let pieces = urlc?.host?.split(separator: "."), !pieces.isEmpty else {
			return nil
		}

		// We're just interested in the top level domain.
		let tld = pieces.count < 2 ? pieces[0] : pieces[pieces.count - 2]
		urlc?.host = "\(tld).onion"

		if urlc?.scheme?.isEmpty ?? true {
			urlc?.scheme = "http"
		}

		urlc?.user = nil
		urlc?.password = nil
		urlc?.port = nil
		urlc?.path = ""
		urlc?.query = nil
		urlc?.fragment = nil

		guard let url = urlc?.url else {
			return nil
		}

		self.init(private: key, forDomain: url)
	}
}

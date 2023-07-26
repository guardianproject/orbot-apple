//
//  URL+Helpers.swift
//  Orbot
//
//  Created by Benjamin Erhart on 22.06.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import Foundation

extension URL {

    static var checkTor = URL(string: "https://check.torproject.org/")!

    static var ddgOnion = URL(string: "https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion/")!

    static var fbOnion = URL(string: "http://fpfjxcrmw437h6z2xl3w4czl55kvkmxpapg37bbopsafdu7q454byxid.onion/")!

    static var neverSsl = URL(string: "http://neverssl.com")!

	static var obCheckTor = URL(string: "onionhttps://check.torproject.org/")!

	static var obAppStore = URL(string: "itms-apps://apple.com/app/id519296448")!


	var contents: String? {
		guard self.isFileURL else {
			return nil
		}

		do {
			return try String(contentsOf: self)
		}
		catch {
			Logger.log(error.localizedDescription, to: Logger.vpnLogFile)

			return nil
		}
	}

	@discardableResult
	func truncate() -> Self {
		if isFileURL {
			try? "".write(to: self, atomically: true, encoding: .utf8)
		}

		return self
	}
}

//
//  AuthKeyItem.swift
//  Orbot Mac
//
//  Created by Benjamin Erhart on 24.08.22.
//  Copyright © 2020 - 2026 Guardian Project. All rights reserved.
//

import Cocoa
import TorCore

class AuthKeyItem: NSCollectionViewItem {

	@IBOutlet weak var addressTf: NSTextField!

	@IBOutlet weak var keyTf: NSTextField!


	func apply(key: TorAuthKey) {
		addressTf.stringValue = key.onionAddress?.absoluteString ?? ""
		keyTf.stringValue = key.key
	}
}

//
//  Settings.swift
//  Orbot
//
//  Created by Benjamin Erhart on 10.11.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import Foundation
import IPtProxyUI

class Settings {

	private static let defaults = UserDefaults(suiteName: Config.groupId)

	class var transport: Transport {
		get {
			guard let raw = defaults?.integer(forKey: "transport") else {
				return .none
			}

			return Transport(rawValue: raw) ?? .none
		}
		set {
			defaults?.set(newValue.rawValue, forKey: "transport")
		}
	}
}

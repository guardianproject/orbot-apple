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

	class var bridge: Bridge {
		get {
			guard let raw = defaults?.integer(forKey: "bridge") else {
				return .none
			}

			return Bridge(rawValue: raw) ?? .none
		}
		set {
			defaults?.set(newValue.rawValue, forKey: "bridge")
		}
	}
}

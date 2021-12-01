//
//  Settings.swift
//  Orbot
//
//  Created by Benjamin Erhart on 10.11.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import Foundation
import IPtProxyUI

class Settings: IPtProxyUI.Settings {

	class override var defaults: UserDefaults? {
		UserDefaults(suiteName: Config.groupId)
	}
}

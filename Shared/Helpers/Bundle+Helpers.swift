//
//  Bundle+displayName.swift
//  Orbot
//
//  Created by Benjamin Erhart on 20.05.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import Foundation

public extension Bundle {

	var displayName: String {
		object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
			?? object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String
			?? ""
    }

	var version: String {
		object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
			?? "unknown"
	}

	var build: String {
		object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
	}
}

//
//  String+Helpers.swift
//  Orbot
//
//  Created by Benjamin Erhart on 13.04.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import Foundation

extension String {

	var nilOnEmpty: String? {
		self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
	}
}

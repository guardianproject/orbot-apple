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
		let text = trimmingCharacters(in: .whitespacesAndNewlines)

		// Transifex just doesn't show empty strings to the translators at all.
		// BartyCrouch also complains. Ugly. We'll se what translators will do...
		if text.isEmpty || text == "__empty__" {
			return nil
		}

		return self
	}
}

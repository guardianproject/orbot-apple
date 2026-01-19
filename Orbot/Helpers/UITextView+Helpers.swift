//
//  UITextView+Helpers.swift
//  Orbot
//
//  Created by Benjamin Erhart on 22.05.20.
//  Copyright © 2020 - 2026 Guardian Project. All rights reserved.
//

import UIKit

extension UITextView {

	var isAtBottom: Bool {
		contentOffset.y >= contentSize.height - frame.size.height - 96
	}

	func scrollToBottom() {
		scrollRangeToVisible(NSRange(location: max(0, text.count - 1), length: 1))
	}
}

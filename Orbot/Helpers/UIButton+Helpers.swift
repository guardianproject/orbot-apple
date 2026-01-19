//
//  UIButton+Helpers.swift
//  Orbot
//
//  Created by Benjamin Erhart on 20.05.20.
//  Copyright © 2020 - 2026 Guardian Project. All rights reserved.
//

import UIKit

extension UIButton {

	func setTitle(_ title: String?) {
		setTitle(title, for: .normal)
		setTitle(title, for: .highlighted)
		setTitle(title, for: .disabled)
		setTitle(title, for: .focused)
		setTitle(title, for: .selected)
	}

	func setAttributedTitle(_ title: NSAttributedString?) {
		setAttributedTitle(title, for: .normal)
		setAttributedTitle(title, for: .highlighted)
		setAttributedTitle(title, for: .disabled)
		setAttributedTitle(title, for: .focused)
		setAttributedTitle(title, for: .selected)
	}
}

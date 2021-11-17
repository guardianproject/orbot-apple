//
//  UIViewController+Helpers.swift
//  Orbot
//
//  Created by Benjamin Erhart on 17.11.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import UIKit

extension UIViewController {

	func present(inNav vc: UIViewController, button: UIBarButtonItem? = nil) {
		let navC = UINavigationController(rootViewController: vc)

		if let button = button {
			navC.modalPresentationStyle = .popover
			navC.popoverPresentationController?.barButtonItem = button
		}
		else {
			navC.modalPresentationStyle = .formSheet
		}

		present(navC, animated: true)
	}
}

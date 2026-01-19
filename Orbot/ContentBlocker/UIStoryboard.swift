//
//  UIStoryboard.swift
//  Orbot
//
//  Created by Benjamin Erhart on 13.01.23.
//  Copyright © 2020 - 2026 Guardian Project. All rights reserved.
//

import UIKit

extension UIStoryboard {

	static let main = UIStoryboard(name: "Main", bundle: nil)

	func instantiateViewController<T: UIViewController>(_ type: T.Type) -> T {
		return instantiateViewController(withIdentifier: String(describing: type)) as! T
	}
}

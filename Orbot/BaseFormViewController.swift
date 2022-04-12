//
//  FormViewController.swift
//  Orbot
//
//  Created by Benjamin Erhart on 11.04.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import UIKit
import Eureka

class BaseFormViewController: FormViewController {

	lazy var closeBt = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(close))


	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.leftBarButtonItem = closeBt
	}


	// MARK: Actions

	@objc func close() {
		navigationController?.dismiss(animated: true)
	}
}

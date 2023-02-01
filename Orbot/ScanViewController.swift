//
//  ScanViewController.swift
//  Orbot
//
//  Created by Benjamin Erhart on 16.01.23.
//  Copyright © 2023 Guardian Project. All rights reserved.
//

import UIKit
import IPtProxyUI

class ScanViewController: BaseScanViewController {


	@IBOutlet weak var hintLb: UILabel! {
		didSet {
			hintLb.text = NSLocalizedString("Scan a bridge QR code", comment: "")
		}
	}

	@IBOutlet weak var preview: UIView!

	@IBOutlet weak var scanLine: UIView!

	@IBOutlet weak var errorLb: UILabel!

	open override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.title = NSLocalizedString("Custom Bridge", comment: "")
	}

	open override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		do {
			try startReading()

			videoPreviewLayer?.frame = preview.layer.bounds
			preview.layer.addSublayer(videoPreviewLayer!)
		}
		catch {
			scanLine.isHidden = true

			errorLb.text = error.localizedDescription
			errorLb.isHidden = false
		}
	}
}

//
//  CustomBridgesViewController.swift
//  Orbot
//
//  Created by Benjamin Erhart on 13.01.23.
//  Copyright © 2023 Guardian Project. All rights reserved.
//

import UIKit
import IPtProxyUI

class CustomBridgesViewController: UIViewController, UITextViewDelegate, ScanQrDelegate {

	static func make() -> CustomBridgesViewController {
		UIStoryboard.main.instantiateViewController(withIdentifier: "custom_bridges_vc") as! CustomBridgesViewController
	}


	weak var delegate: BridgesConfDelegate?


	@IBOutlet weak var explanationLb: UILabel! {
		didSet {
			explanationLb.text = NSLocalizedString("A custom bridge is provided by someone you know. Ask within your trusted networks and organizations to see if anyone is hosting one.", comment: "")
		}
	}

	@IBOutlet weak var bridgeLinesTv: UITextView? {
		didSet {
			bridgeLinesTv?.text = delegate?.customBridges?.joined(separator: "\n")
			hintLb?.isHidden = !(bridgeLinesTv?.text.isEmpty ?? true)
		}
	}

	@IBOutlet weak var hintLb: UILabel? {
		didSet {
			hintLb?.text = NSLocalizedString("Enter bridge address", comment: "")
			hintLb?.isHidden = !(bridgeLinesTv?.text.isEmpty ?? true)
		}
	}

	@IBOutlet weak var qrBt: UIButton! {
		didSet {
			qrBt.accessibilityLabel = NSLocalizedString("Scan QR Code", bundle: .iPtProxyUI, comment: "#bc-ignore!")
		}
	}

	@IBOutlet weak var captionLb: UILabel! {
		didSet {
			captionLb.text = NSLocalizedString("You can enter multiple bridge addresses.", comment: "")
		}
	}

	@IBOutlet weak var saveBt: UIButton! {
		didSet {
			saveBt.setTitle(NSLocalizedString("Save", bundle: .iPtProxyUI, comment: "#bc-ignore!"))
		}
	}


	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.title = NSLocalizedString("Custom Bridge", comment: "")

		view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
	}


	// MARK: UITextViewDelegate

	func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
		hintLb?.isHidden = true

		return true
	}

	func textViewDidEndEditing(_ textView: UITextView) {
		hintLb?.isHidden = !textView.text.isEmpty
	}


	// MARK: ScanQrDelegate

	func scanned(value raw: String?) {
		// They really had to use JSON for content encoding but with illegal single quotes instead
		// of double quotes as per JSON standard. Srsly?
		if let data = raw?.replacingOccurrences(of: "'", with: "\"").data(using: .utf8),
			let newBridges = try? JSONSerialization.jsonObject(with: data, options: []) as? [String] {

			bridgeLinesTv?.text = newBridges.joined(separator: "\n")
		}
		else {
			AlertHelper.present(self, message:
				String(format: NSLocalizedString(
					"QR Code could not be decoded! Are you sure you scanned a QR code from %@?",
					bundle: .iPtProxyUI, comment: ""), IPtProxyUI.CustomBridgesViewController.bridgesUrl))
		}
	}


	// MARK: Actions

	@IBAction
	func save() {
		navigationController?.popViewController(animated: true)

		delegate?.customBridges = bridgeLinesTv?.text?
				.components(separatedBy: "\n")
				.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
				.filter({ !$0.isEmpty && !$0.hasPrefix("//") && !$0.hasPrefix("#") })

		if delegate?.customBridges?.isEmpty ?? true {
			if delegate?.transport == .custom {
				delegate?.transport = .none
			}
		}
		else {
			delegate?.transport = .custom
		}

		delegate?.save()
	}

	@IBAction
	func scan() {
		let vc = ScanQrViewController()
		vc.delegate = self

		navigationController?.pushViewController(vc, animated: true)
	}


	// MARK: Private Methods

	@objc
	private func dismissKeyboard() {
		view.endEditing(true)
	}
}

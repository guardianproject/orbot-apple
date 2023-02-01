//
//  CustomBridgesViewController.swift
//  Orbot
//
//  Created by Benjamin Erhart on 13.01.23.
//  Copyright © 2023 Guardian Project. All rights reserved.
//

import UIKit
import IPtProxyUI
import PhotosUI

class CustomBridgesViewController: UIViewController, UITextViewDelegate, ScanQrDelegate, PHPickerViewControllerDelegate {

	static func make() -> Self {
		UIStoryboard.main.instantiateViewController(withIdentifier: "custom_bridges_vc") as! Self
	}


	weak var delegate: BridgesConfDelegate?


	@IBOutlet weak var explanationLb: UILabel! {
		didSet {
			explanationLb.text = NSLocalizedString("A custom bridge is provided by someone you know. Ask within your trusted networks and organizations to see if anyone is hosting one.", comment: "")
		}
	}

	@IBOutlet weak var bridgeLinesTv: UITextView? {
		didSet {
			set(bridges: delegate?.customBridges)
		}
	}

	@IBOutlet weak var hintLb: UILabel? {
		didSet {
			hintLb?.text = NSLocalizedString("Enter bridge address", comment: "")
			hintLb?.isHidden = !(bridgeLinesTv?.text.isEmpty ?? true)
		}
	}

	@IBOutlet weak var fileBt: UIButton! {
		didSet {
			fileBt.accessibilityLabel  = IPtProxyUI.L10n.uploadQrCode
		}
	}

	@IBOutlet weak var qrBt: UIButton! {
		didSet {
			qrBt.accessibilityLabel = IPtProxyUI.L10n.scanQrCode
		}
	}

	@IBOutlet weak var captionLb: UILabel! {
		didSet {
			captionLb.text = NSLocalizedString("You can enter multiple bridge addresses.", comment: "")
		}
	}

	@IBOutlet weak var saveBt: UIButton! {
		didSet {
			saveBt.setTitle(IPtProxyUI.L10n.save)
		}
	}


	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.title = NSLocalizedString("Custom Bridge", comment: "")

		view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let scanVc = segue.destination as? ScanViewController {
			scanVc.delegate = self
		}
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

	func scanned(bridges: [String]) {
		navigationController?.popViewController(animated: true)

		set(bridges: bridges)
	}

	func scanned(error: Error) {
		navigationController?.popViewController(animated: true)

		AlertHelper.present(self, message: error.localizedDescription)
	}


	// MARK: Actions

	@IBAction
	func save() {
		navigationController?.popViewController(animated: true)

		Helpers.update(delegate: delegate, bridgeLinesTv?.text)

		delegate?.save()
	}

	@IBAction
	func pickImage() {
		var conf = PHPickerConfiguration()
		conf.filter = PHPickerFilter.images

		let vc = PHPickerViewController(configuration: conf)
		vc.delegate = self

		present(vc, animated: true)
	}


	// MARK: PHPickerViewControllerDelegate

	func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
		picker.dismiss(animated: true)

		results.first?.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
			guard let self = self
			else {
				return
			}

			let bridges = BaseScanViewController.extractBridges(from: object as? UIImage)

			DispatchQueue.main.async {
				if let bridges = bridges {
					self.set(bridges: bridges)
				}
				else {
					AlertHelper.present(self, message: ScanError.notBridges.localizedDescription)
				}
			}
		}
	}


	// MARK: Private Methods

	@objc
	private func dismissKeyboard() {
		view.endEditing(true)
	}

	private func set(bridges: [String]?) {
		bridgeLinesTv?.text = bridges?.joined(separator: "\n")
		hintLb?.isHidden = !(bridgeLinesTv?.text.isEmpty ?? true)
	}
}

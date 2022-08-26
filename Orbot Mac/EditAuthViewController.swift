//
//  EditAuthViewController.swift
//  Orbot Mac
//
//  Created by Benjamin Erhart on 24.08.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import Cocoa
import Tor
import IPtProxyUI

protocol EditAuthDelegate: AnyObject {

	func set(key: TorAuthKey)

	func remove(key: TorAuthKey)
}

class EditAuthViewController: NSViewController, NSWindowDelegate {

	var key: TorAuthKey?

	weak var delegate: EditAuthDelegate?


	@IBOutlet weak var addressTf: NSTextField!

	@IBOutlet weak var keyTf: NSTextField! {
		didSet {
			keyTf.placeholderString = NSLocalizedString("Key", comment: "")
		}
	}

	@IBOutlet weak var addBt: NSButton!

	@IBOutlet weak var deleteBt: NSButton! {
		didSet {
			deleteBt.title = NSLocalizedString("Delete", comment: "")
		}
	}

	@IBOutlet weak var cancelBt: NSButton! {
		didSet {
			cancelBt.title = NSLocalizedString("Cancel", bundle: .iPtProxyUI, comment: "#bc-ignore!")
		}
	}


	override func viewDidAppear() {
		super.viewDidAppear()

		view.window?.delegate = self

		view.window?.defaultButtonCell = addBt.cell as? NSButtonCell

		if key == nil {
			view.window?.title = NSLocalizedString("Add v3 Onion Service Auth Cookie", comment: "")
		}
		else {
			view.window?.title = NSLocalizedString("Edit v3 Onion Service Auth Cookie", comment: "")
		}

		addressTf.stringValue = key?.onionAddress?.absoluteString ?? ""
		keyTf.stringValue = key?.key ?? ""

		deleteBt.isHidden = key == nil

		addBt.title = key == nil
			? NSLocalizedString("Add", comment: "")
			: NSLocalizedString("Edit", comment: "")
	}


	// MARK: NSWindowDelegate

	func windowWillClose(_ notification: Notification) {
		NSApp.stopModal()
	}


	// MARK: Actions

	@IBAction func add(_ sender: Any) {
		if let key = TorAuthKey(private: keyTf.stringValue, forDomain: addressTf.stringValue) {
			delegate?.set(key: key)
		}

		NSApp.stopModal()
	}

	@IBAction func delete(_ sender: Any) {
		if let key = key {
			delegate?.remove(key: key)
		}

		NSApp.stopModal()
	}

	@IBAction func cancel(_ sender: Any) {
		NSApp.stopModal()
	}
}

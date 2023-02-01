//
//  CaptchaViewController.swift
//  Orbot
//
//  Created by Benjamin Erhart on 16.01.23.
//  Copyright © 2023 Guardian Project. All rights reserved.
//

import UIKit
import IPtProxyUI
import MBProgressHUD

class CaptchaViewController: UIViewController {

	open weak var delegate: BridgesConfDelegate?

	@IBOutlet weak var captchaIv: UIImageView! {
		didSet {
			captchaIv.accessibilityLabel = IPtProxyUI.L10n.captchaImage
		}
	}

	@IBOutlet weak var refreshBt: UIButton! {
		didSet {
			refreshBt.accessibilityLabel = NSLocalizedString("Refresh", comment: "")
		}
	}

	@IBOutlet weak var solutionTf: UITextField! {
		didSet {
			solutionTf.placeholder = NSLocalizedString("Enter text above", comment: "")
		}
	}

	@IBOutlet weak var saveBt: UIButton! {
		didSet {
			saveBt.setTitle(IPtProxyUI.L10n.save)
			saveBt.isEnabled = false
		}
	}


	private var challenge: String?


	static func make() -> Self {
		UIStoryboard.main.instantiateViewController(withIdentifier: "captcha_vc") as! Self
	}


	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.title = NSLocalizedString("Solve CAPTCHA", comment: "")

		view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		delegate?.startMeek()

		fetchCaptcha(nil)
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		delegate?.stopMeek()
	}


	// MARK: Actions

	@IBAction
	func save() {
		dismissKeyboard()
		let hud = MBProgressHUD.showAdded(to: view, animated: true)

		MoatViewController.requestBridges(delegate, challenge, solutionTf.text) { [weak self] bridges, error in
			DispatchQueue.main.async {
				guard let self = self else {
					return
				}

				hud.hide(animated: true)

				if let error = error {
					AlertHelper.present(self, message: error.localizedDescription)
					return
				}

				guard let bridges = bridges else {
					return
				}

				self.delegate?.customBridges = bridges
				self.delegate?.transport = .custom

				self.delegate?.save()

				self.navigationController?.popViewController(animated: true)
			}
		}
	}

	@IBAction
	func fetchCaptcha(_ sender: Any?) {
		refreshBt.isEnabled = false
		saveBt.isEnabled = false
		let hud = MBProgressHUD.showAdded(to: view, animated: true)

		MoatViewController.fetchCaptcha(delegate) { [weak self] challenge, captcha, error in
			DispatchQueue.main.async {
				guard let self = self else {
					return
				}

				hud.hide(animated: true)
				self.refreshBt.isEnabled = true
				self.solutionDidChange()

				if let error = error {
					AlertHelper.present(self, message: error.localizedDescription)
					return
				}

				self.challenge = challenge

				if let captcha = captcha {
					self.captchaIv.image = UIImage(data: captcha)
				}
			}
		}
	}


	@IBAction
	func solutionDidChange() {
		saveBt.isEnabled = !(solutionTf.text?.isEmpty ?? true)
	}


	// MARK: Private Methods

	@objc
	private func dismissKeyboard() {
		view.endEditing(true)
	}
}

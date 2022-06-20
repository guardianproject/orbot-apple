//
//  ApiAccessViewController.swift
//  Orbot
//
//  Created by Benjamin Erhart on 06.05.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import UIKit
import IPtProxyUI

class ApiAccessViewController: UITableViewController, UITextFieldDelegate {

	private lazy var tokens = Settings.apiAccessTokens {
		didSet {
			Settings.apiAccessTokens = tokens
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.title = NSLocalizedString("API Access", comment: "")

		navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(close))

		tableView.register(ApiAccessCell.nib, forCellReuseIdentifier: ApiAccessCell.reuseId)
	}


	// MARK: UITableViewDataSource

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return tokens.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: ApiAccessCell.reuseId, for: indexPath) as! ApiAccessCell

		let token = tokens[indexPath.row]

		cell.appIdLb?.text = token.appId
		cell.keyLb?.text = token.key

		cell.bypassLb?.text = token.bypass
			? NSLocalizedString("Bypass: granted", comment: "")
			: NSLocalizedString("Bypass: denied", comment: "")

		return cell
	}

	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			tokens.remove(at: indexPath.row)

			tableView.deleteRows(at: [indexPath], with: .automatic)

			// No bypassing apps allowed anymore. Remove bypass, if any.
			if tokens.first(where: { $0.bypass }) == nil && Settings.bypassPort != nil {
				Settings.bypassPort = nil

				// Restart with deactivated bypass.
				restartVpn()
			}
		}
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		showAlert(tokens[indexPath.row], indexPath) { [weak self] success in
			self?.tableView?.deselectRow(at: indexPath, animated: true)
		}
	}


	// MARK: Actions

	@objc func close() {
		navigationController?.dismiss(animated: true) {
			((UIApplication.shared.delegate?.window??.rootViewController as? UINavigationController)?.viewControllers.first as? MainViewController)?
				.updateMenu()
		}
	}


	func addToken(_ appId: String, _ needsBypass: Bool, _ completion: @escaping (_ token: ApiToken?) -> Void) {
		let token = ApiToken(appId: appId, key: UUID().uuidString, bypass: needsBypass)

		showAlert(token, nil) { [weak self] token in
			if token != nil {
				self?.tableView?.reloadData()
			}

			completion(token)
		}
	}


	// MARK: UITextFieldDelegate

	func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
		return false
	}


	// MARK: Private Methods

	private func showAlert(_ token: ApiToken, _ indexPath: IndexPath?, _ completion: @escaping (_ token: ApiToken?) -> Void) {
		let title: String
		var message: String?
		let actionTitle: String

		if indexPath != nil {
			title = NSLocalizedString("API Access Token", comment: "")
			message = nil
			actionTitle = NSLocalizedString("Copy to Clipboard", comment: "")
		}
		else {
			title = NSLocalizedString("Add API Access Token", comment: "")
			message = NSLocalizedString("Another app requested an API access token.", comment: "")

			if token.bypass {
				message! += "\n\n"
				+ String(format: NSLocalizedString("That app also wants to bypass %@!", comment: ""), Bundle.main.displayName)

				actionTitle = NSLocalizedString("Allow Access and Bypass", comment: "")
			}
			else {
				actionTitle = NSLocalizedString("Allow Access", comment: "")
			}
		}

		let alert = AlertHelper.build(
			message: message,
			title: title,
			actions: [AlertHelper.cancelAction(handler: { _ in completion(nil) })])

		alert.addAction(AlertHelper.defaultAction(actionTitle) { [weak self] action in

			if token.bypass {
				// User granted bypass access. Switch on, if not yet enabled.
				if Settings.bypassPort == nil {
					Settings.bypassPort = 1 // Will be set to a random valid port number, regardless of this value.

					// Restart with activated bypass.
					self?.restartVpn()
				}
			}

			UIPasteboard.general.string = token.key

			if indexPath == nil {
				self?.tokens.removeAll(where: { $0.appId == token.appId })

				self?.tokens.append(token)
			}

			completion(token)
		})

		if let indexPath = indexPath {
			alert.addAction(AlertHelper.destructiveAction(NSLocalizedString("Delete", comment: "")) { [weak self] _ in
				self?.tableView(self!.tableView, commit: .delete, forRowAt: indexPath)
			})
		}

		AlertHelper.addTextField(alert, text: token.appId) { tf in
			tf.delegate = self
		}

		AlertHelper.addTextField(alert, text: token.key) { tf in
			tf.delegate = self
		}

		present(alert, animated: true)
	}

	private func restartVpn() {
		switch VpnManager.shared.sessionStatus {
		case .connecting, .connected, .reasserting:
			VpnManager.shared.disconnect()
			VpnManager.shared.connect()

			// We need to sleep a little, otherwise the queued start on the
			// main thread will never happen.
			usleep(500000)

		default:
			break
		}
	}
}

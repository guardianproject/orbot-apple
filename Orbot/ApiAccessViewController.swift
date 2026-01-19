//
//  ApiAccessViewController.swift
//  Orbot
//
//  Created by Benjamin Erhart on 06.05.22.
//  Copyright © 2020 - 2026 Guardian Project. All rights reserved.
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

		cell.appIdLb?.text = token.friendlyName
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
		navigationController?.dismiss(animated: true)

		UIApplication.shared.mainVc?.updateMenu()
	}


	func addToken(_ appId: String, _ appName: String?, _ needsBypass: Bool, _ completion: @escaping (_ token: ApiToken?) -> Void) {
		let token = ApiToken(appId: appId, key: UUID().uuidString, appName: appName, bypass: needsBypass)

		let vc = UIStoryboard.main.instantiateViewController(AccessRequestViewController.self)
		vc.token = token
		vc.completion = { granted in
			self.tokens.removeAll(where: { $0.appId == token.appId })

			if granted {
				self.tokens.append(token)

				UIPasteboard.general.string = token.key

				// User granted bypass access. Switch on, if not yet enabled.
				if token.bypass && Settings.bypassPort == nil {
					Settings.bypassPort = 1 // Will be set to a random valid port number, regardless of this value.

					// Restart with activated bypass.
					self.restartVpn()
				}
			}

			// Since we removed ourselves, we need to find the navigationController on the AccessRequestViewController.
			vc.navigationController?.dismiss(animated: true)
			self.close()

			completion(granted ? token : nil)
		}

		navigationController?.viewControllers = [vc]
	}


	// MARK: UITextFieldDelegate

	func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
		return false
	}


	// MARK: Private Methods

	private func showAlert(_ token: ApiToken, _ indexPath: IndexPath, _ completion: @escaping (_ token: ApiToken?) -> Void) {
		let alert = AlertHelper.build(
			title: NSLocalizedString("API Access Token", comment: ""),
			actions: [AlertHelper.cancelAction(handler: { _ in completion(nil) })])

		alert.addAction(AlertHelper.defaultAction(NSLocalizedString("Copy to Clipboard", comment: "")) { action in
			UIPasteboard.general.string = token.key

			completion(token)
		})

		alert.addAction(AlertHelper.destructiveAction(L10n.delete) { [weak self] _ in
			self?.tableView(self!.tableView, commit: .delete, forRowAt: indexPath)
		})

		AlertHelper.addTextField(alert, text: token.friendlyName) { tf in
			tf.delegate = self
		}

		AlertHelper.addTextField(alert, text: token.key) { tf in
			tf.delegate = self
		}

		present(alert, animated: true)
	}

	private func restartVpn() {
		if VpnManager.shared.isConnected {
			VpnManager.shared.disconnect(explicit: false)
			VpnManager.shared.connect()

			// We need to sleep a little, otherwise the queued start on the
			// main thread will never happen.
			usleep(500000)
		}
	}
}

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
	}


	// MARK: UITableViewDataSource

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return tokens.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "token-cell")
		?? UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "token-cell")

		let token = tokens[indexPath.row]

		cell.textLabel?.text = token.appId
		cell.detailTextLabel?.text = token.key

		return cell
	}

	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			tokens.remove(at: indexPath.row)

			tableView.deleteRows(at: [indexPath], with: .automatic)
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


	func addToken(_ appId: String, _ completion: @escaping (_ token: ApiToken?) -> Void) {
		let token = ApiToken(appId: appId, key: UUID().uuidString)

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
		let message: String?
		let actionTitle: String

		if indexPath != nil {
			title = NSLocalizedString("API Access Token", comment: "")
			message = nil
			actionTitle = NSLocalizedString("Copy to Clipboard", comment: "")
		}
		else {
			title = NSLocalizedString("Add API Access Token", comment: "")
			message = NSLocalizedString("Another app requested an API access token.", comment: "")
			actionTitle = NSLocalizedString("Allow Access", comment: "")
		}

		let alert = AlertHelper.build(
			message: message,
			title: title,
			actions: [AlertHelper.cancelAction(handler: { _ in completion(nil) })])

		alert.addAction(AlertHelper.defaultAction(actionTitle) { [weak self] _ in
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
}

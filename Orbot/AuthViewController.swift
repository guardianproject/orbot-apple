//
//  AuthViewController.swift
//  Orbot
//
//  Created by Benjamin Erhart on 11.11.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import UIKit
import Tor

class AuthViewController: UITableViewController, ScanQrDelegate {

	private var auth: TorOnionAuth?

	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.title = NSLocalizedString("Auth Cookies", comment: "")

		navigationItem.leftBarButtonItem = UIBarButtonItem(
			barButtonSystemItem: .close, target: self, action: #selector(close))

		navigationItem.rightBarButtonItems = [
			UIBarButtonItem(
				barButtonSystemItem: .add, target: self, action: #selector(add)),
			UIBarButtonItem(
				barButtonSystemItem: .camera, target: self, action: #selector(qr))]

		if let authDir = FileManager.default.torAuthDir {
			auth = TorOnionAuth(withPrivateDir: authDir, andPublicDir: authDir)
		}
	}


	// MARK: UITableViewDataSource

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return auth?.keys.count ?? 0
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cookie-cell")
		?? UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "cookie-cell")

		let key = auth?.keys[indexPath.row]

		cell.textLabel?.text = key?.onionAddress?.absoluteString
		cell.detailTextLabel?.text = key?.key

		return cell
	}

	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			auth?.removeKey(at: indexPath.row)

			tableView.deleteRows(at: [indexPath], with: .automatic)
		}
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let key = auth?.keys[indexPath.row]

		showAlert(
			title: NSLocalizedString("Edit v3 Onion Service Auth Cookie", comment: ""),
			actionTitle: NSLocalizedString("Edit", comment: ""),
			url: key?.onionAddress,
			key: key?.key) { [weak self] success in
				if success {
					self?.tableView?.reloadRows(at: [indexPath], with: .automatic)
				}
				else {
					self?.tableView?.deselectRow(at: indexPath, animated: true)
				}
			}
	}


	// MARK: Actions

	@objc func close() {
		navigationController?.dismiss(animated: true)
	}

	@objc func add() {
		addKey(nil, nil)
	}

	@objc func qr() {
		let vc = ScanQrViewController()
		vc.delegate = self

		navigationController?.pushViewController(vc, animated: true)
	}


	// MARK: ScanQrDelegate

	func scanned(value: String?) {
		if let value = value,
		   var urlc = URLComponents(string: value),
		   urlc.host?.lowercased().hasSuffix(".onion") ?? false
		{
			// Either use the URL password or the first "key" query item as the key.
			let key = urlc.password
			?? urlc.queryItems?.first(where: { $0.name.caseInsensitiveCompare("key") == .orderedSame })?.value

			// Remove all the rest, that's neither needed nor useful.
			urlc.user = nil
			urlc.password = nil
			urlc.port = nil
			urlc.path = ""
			urlc.query = nil
			urlc.fragment = nil

			addKey(urlc.url, key)
		}
		else {
			AlertHelper.present(self, message: NSLocalizedString(
				"QR Code could not be decoded! Are you sure you scanned a .onion URL?",
				comment: ""))
		}

	}

	func addKey(_ url: URL?, _ key: String?) {
		let old = auth?.keys.count ?? 0

		showAlert(
			title: NSLocalizedString("Add v3 Onion Service Auth Cookie", comment: ""),
			actionTitle: NSLocalizedString("Add", comment: ""),
			url: url,
			key: key) { [weak self] success in
				if success {
					if self?.auth?.keys.count ?? 0 > old {
						self?.tableView?.insertRows(
							at: [IndexPath(row: (self?.auth?.keys.count ?? 1) - 1, section: 0)],
							with: .automatic)
					}
					else {
						self?.tableView.reloadData()
					}
				}

				VpnManager.shared.configChanged()
			}
	}


	// MARK: Private Methods

	private func showAlert(title: String, actionTitle: String, url: URL?, key: String?, completion: @escaping (_ success: Bool) -> Void) {
		let alert = AlertHelper.build(
			title: title,
			actions: [AlertHelper.cancelAction(handler: { _ in completion(false) })])

		alert.addAction(AlertHelper.defaultAction(actionTitle, handler: { [weak self] _ in
			guard let rawUrl = alert.textFields?.first?.text,
				  let key = alert.textFields?.last?.text
			else {
				return completion(false)
			}

			var urlc = URLComponents(string: rawUrl)

			// If you just enter some alhpanumerics, it ends up as the path,
			// but just to be sure, we copy from everywhere else, too.
			if urlc?.host?.isEmpty ?? true {
				let path = urlc?.path.isEmpty ?? true ? nil : urlc?.path
				var host = path ?? urlc?.query ?? urlc?.fragment ?? urlc?.scheme ?? urlc?.user
				host = host ?? urlc?.password
				urlc?.host = host
			}

			guard let pieces = urlc?.host?.split(separator: "."), !pieces.isEmpty else {
				return completion(false)
			}

			// We're just interested in the top level domain.
			let tld = pieces.count < 2 ? pieces[0] : pieces[pieces.count - 2]
			urlc?.host = "\(tld).onion"

			if urlc?.scheme?.isEmpty ?? true {
				urlc?.scheme = "http"
			}

			urlc?.user = nil
			urlc?.password = nil
			urlc?.port = nil
			urlc?.path = ""
			urlc?.query = nil
			urlc?.fragment = nil

			guard let url = urlc?.url else {
				return completion(false)
			}

			self?.auth?.set(TorAuthKey(private: key, forDomain: url))

			completion(true)
		}))

		AlertHelper.addTextField(alert, placeholder: "http://example.onion", text: url?.absoluteString) { tf in
			tf.keyboardType = .URL
		}

		AlertHelper.addTextField(alert, placeholder: NSLocalizedString("Key", comment: ""), text: key)

		present(alert, animated: true)
	}
}

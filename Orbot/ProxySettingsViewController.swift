//
//  ProxySettingsViewController.swift
//  Orbot
//
//  Created by Benjamin Erhart on 26.09.25.
//  Copyright © 2020 - 2026 Guardian Project. All rights reserved.
//

import UIKit
import Eureka

class ProxySettingsViewController: BaseFormViewController {

	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.title = L10n.proxy

		navigationItem.leftBarButtonItem = nil
		navigationItem.rightBarButtonItem  = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteProxy))


		form
		+++ Section()
		<<< PickerInlineRow<String>("scheme") {
			$0.title = L10n.proxyType
			$0.options = ["https", "socks4", "socks5"]
			$0.value = Settings.proxy?.scheme ?? "socks5"
		}
		.onChange({ [weak self] row in
			let portRow = self?.form.rowBy(tag: "port") as? IntRow
			portRow?.placeholder = URL.defaultProxyPort(for: row.value)
			portRow?.updateCell()

			self?.updateProxy()
		})

		<<< TextRow("host") {
			$0.title = L10n.proxyHost
			$0.placeholder = "127.0.0.1"
			$0.value = Settings.proxy?.host
			$0.add(rule: RuleRequired())
			$0.validationOptions = .validatesAlways
			$0.turnOffAutoCorrect()
		}
		.cellUpdate({ cell, row in
			cell.titleLabel?.textColor = row.isValid ? .label :.systemRed
		})
		.onChange({ [weak self] row in
			self?.updateProxy()
		})

		<<< IntRow("port") {
			$0.title = L10n.proxyPort
			$0.placeholder = URL.defaultProxyPort(for: Settings.proxy?.scheme)
			$0.value = Settings.proxy?.port
			$0.add(rule: RuleGreaterThan(min: 0))
			$0.add(rule: RuleSmallerThan(max: 65536))
			$0.validationOptions = .validatesAlways
			$0.formatter = nil
		}
		.cellUpdate({ cell, row in
			cell.titleLabel?.textColor = row.isValid ? .label :.systemRed
		})
		.onChange({ [weak self] row in
			self?.updateProxy()
		})

		<<< TextRow("username") {
			$0.title = L10n.proxyUsername
			$0.value = Settings.proxy?.user
			$0.add(rule: RuleMaxLength(maxLength: 255))
			$0.validationOptions = .validatesAlways
			$0.turnOffAutoCorrect()
		}
		.onChange({ [weak self] row in
			self?.updateProxy()
		})

		<<< TextRow("password") {
			$0.title = L10n.proxyPassword
			$0.value = Settings.proxy?.password
			$0.add(rule: RuleMaxLength(maxLength: 255))
			$0.validationOptions = .validatesAlways
			$0.turnOffAutoCorrect()
		}
		.onChange({ [weak self] row in
			self?.updateProxy()
		})
	}

	private func updateProxy() {
		var urlc = URLComponents()

		urlc.scheme = (form.rowBy(tag: "scheme") as? PickerInlineRow<String>)?.value
		urlc.host = (form.rowBy(tag: "host") as? TextRow)?.value

		if let port = (form.rowBy(tag: "port") as? IntRow)?.value, port > 0 && port < 65536 {
			urlc.port = port
		}
		else {
			urlc.port = nil
		}

		urlc.user = (form.rowBy(tag: "username") as? TextRow)?.value
		urlc.password = (form.rowBy(tag: "password") as? TextRow)?.value

		if !(urlc.host?.isEmpty ?? true) {
			Settings.proxy = urlc.url
		}
		else {
			Settings.proxy = nil
		}
	}

	// MARK: Actions

	@objc func deleteProxy() {
		for tag in ["host", "port", "username", "password"] {
			let row = form.rowBy(tag: tag)
			row?.baseValue = nil
			row?.updateCell()
		}

		updateProxy()
	}
}

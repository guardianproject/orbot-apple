//
//  ContentBlockerViewController.swift
//  Orbot
//
//  Created by Benjamin Erhart on 11.04.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import UIKit
import Eureka
import IPtProxyUI
import MBProgressHUD

class ContentBlockerViewController: BaseFormViewController {

	private var sources = [BlockerSource]()

	override func viewDidLoad() {
		super.viewDidLoad()

		sources = Settings.blockSources.compactMap { $0.blockerSource }

		navigationItem.title = NSLocalizedString("Content Blocker", comment: "")

		form
		+++ LabelRow {
			$0.value = String(
				format: NSLocalizedString(
					"%1$@ provides a \"Content Blocker\" extension for Safari and all other browsers in iOS:",
					comment: ""),
				Bundle.main.displayName) + "\n"
			+ String(
				format: NSLocalizedString(
					"A list of domains to block but also to force an upgrade to HTTPS to keep you secure on the net, even when the %1$@ VPN is not running!",
					comment: ""),
				Bundle.main.displayName) + "\n\n"
			+ String(
				format: NSLocalizedString(
					"Go to the iOS Settings App -> Safari -> Extensions and activate the %1$@ Content Blocker for this to work!",
					comment: ""),
				Bundle.main.displayName) + "\n\n"
			+ String(
				format: NSLocalizedString(
					"Tap the \"%1$@\" button below, to generate the latest block- and upgrade-list.",
					comment: ""),
				NSLocalizedString("Update", comment: ""))

			$0.cellStyle = .subtitle
			$0.cell.detailTextLabel?.numberOfLines = 0
		}

		+++ SwitchRow {
			$0.title = NSLocalizedString("HTTPS-Upgrade from Chromium's HSTS list", comment: "")
			$0.value = sources.contains(where: { $0 is ChromiumHsts })

			$0.cell.textLabel?.numberOfLines = 0
		}
		.onChange { [weak self] row in
			if row.value ?? false {
				if !Settings.blockSources.contains(where: { $0 == .chromiumHsts }) {
					Settings.blockSources.append(.chromiumHsts)
				}

				if !(self?.sources.contains(where: { $0 is ChromiumHsts }) ?? false) {
					self?.sources.append(ChromiumHsts())
				}
			}
			else {
				(self?.sources.first(where: { $0 is ChromiumHsts }) ?? ChromiumHsts()).remove()

				self?.sources.removeAll { $0 is ChromiumHsts }
				Settings.blockSources.removeAll { $0 == .chromiumHsts }
			}

			self?.form.rowBy(tag: "chromium-hsts-info")?.updateCell()
		}

		<<< LabelRow("chromium-hsts-info") {
			$0.cellStyle = .subtitle
		}
		.cellUpdate { [weak self] _, row in
			row.value = String.localizedStringWithFormat(
				NSLocalizedString("%u domain(s)", comment: ""),
				self?.sources.first(where: { $0 is ChromiumHsts })?.count ?? 0)
		}

		+++ ButtonRow {
			$0.title = NSLocalizedString("Update", comment: "")
		}
		.onCellSelection { [weak self] _, _ in
			let hud: MBProgressHUD?

			if let view = self?.view {
				hud = MBProgressHUD.showAdded(to: view, animated: true)
				hud?.label.text = NSLocalizedString("Updating Block List…", comment: "")
				hud?.removeFromSuperViewOnHide = true
			}
			else {
				hud = nil
			}

			let dg = DispatchGroup()

			for source in self?.sources ?? [] {
				dg.enter()

				source.update { [weak self] error in
					if let error = error {
						if let self = self {
							AlertHelper.present(self, message: error.localizedDescription)
						}
						else {
							print("[ContentBlockerViewController] blockerSourceType=\(type(of: source)) error=\(error)")
						}

						dg.leave()
					}

					do {
						try source.write()
					}
					catch {
						if let self = self {
							AlertHelper.present(self, message: error.localizedDescription)
						}
						else {
							print("[ContentBlockerViewController] blockerSourceType=\(type(of: source)) error=\(error)")
						}
					}

					dg.leave()
				}
			}

			dg.notify(queue: .main) {
				hud?.hide(animated: true, afterDelay: 0.5)

				self?.form.rowBy(tag: "chromium-hsts-info")?.updateCell()
			}
		}
	}
}

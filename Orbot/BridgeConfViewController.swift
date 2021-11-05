//
//  BridgeConfViewController.swift
//  Orbot
//
//  Created by Benjamin Erhart on 14.01.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import UIKit
import Eureka
import NetworkExtension

protocol BridgeConfDelegate: AnyObject {

    var bridgesType: NETunnelProviderProtocol.Transport { get set }

	var customBridges: [String]? { get set }

	func connect()
}

class BridgeConfViewController: FormViewController, UINavigationControllerDelegate,
                                BridgeConfDelegate {

	class func present(from: UIViewController) {
        from.present(UINavigationController(rootViewController: BridgeConfViewController()), animated: true)
	}

	private let bridgesSection: SelectableSection<ListCheckRow<NETunnelProviderProtocol.Transport>> = {
		let description = [
			NSLocalizedString("If you are in a country or using a connection that censors Tor, you might need to use bridges.",
							  comment: ""),
			"",
			String(format: NSLocalizedString("%1$@ %2$@ makes your traffic appear \"random\".",
							  comment: ""), "\u{2022}", "obfs4"),
			String(format: NSLocalizedString("%1$@ %2$@ makes your traffic look like a phone call to a random user on the net.",
							  comment: ""), "\u{2022}", "snowflake"),
			"",
			NSLocalizedString("If one type of bridge does not work, try using a different one.",
							  comment: "")
			]

		return SelectableSection<ListCheckRow<NETunnelProviderProtocol.Transport>>(
			header: "", footer: description.joined(separator: "\n"),
			selectionType: .singleSelection(enableDeselection: false))
	}()

    var bridgesType = VpnManager.shared.transport {
		didSet {
			for row in bridgesSection {
				if (row as? ListCheckRow<NETunnelProviderProtocol.Transport>)?.value == bridgesType {
					row.select()
				}
				else {
					row.deselect()
				}
			}
		}
	}

    var customBridges: [String]? = nil

	override func viewDidLoad() {
		super.viewDidLoad()

		navigationController?.delegate = self

		navigationItem.leftBarButtonItem = UIBarButtonItem(
			barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
		navigationItem.title = NSLocalizedString("Bridge Configuration", comment: "")
		navigationItem.rightBarButtonItem = UIBarButtonItem(
			title: NSLocalizedString("Connect", comment: ""), style: .done,
			target: self, action: #selector(connect))

		let bridges: [NETunnelProviderProtocol.Transport: String] = [
			.direct: NSLocalizedString("No Bridges", comment: ""),
			.obfs4: String(format: NSLocalizedString("Built-in %@", comment: ""), "obfs4"),
			.snowflake: String(format: NSLocalizedString("Built-in %@", comment: ""), "snowflake"),
//			.custom: NSLocalizedString("Custom Bridges", comment: ""),
		]

		bridgesSection.onSelectSelectableRow = { [weak self] _, row in
//			if row.value == .custom {
//				let vc = CustomBridgesViewController()
//				vc.delegate = self
//
//				self?.navigationController?.pushViewController(vc, animated: true)
//			}
		}

		form
			+++ ButtonRow() {
				$0.title = NSLocalizedString("Request Bridges from torproject.org", comment: "")
			}
			.onCellSelection { [weak self] _, _ in
				let vc = MoatViewController()
				vc.delegate = self

				self?.navigationController?.pushViewController(vc, animated: true)
			}

			+++ bridgesSection

		for option in bridges.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
			form.last! <<< ListCheckRow<NETunnelProviderProtocol.Transport>() {
				$0.title = option.value
				$0.selectableValue = option.key
				$0.value = option.key == bridgesType ? bridgesType : nil
			}
		}
	}


	// MARK: UINavigationControllerDelegate

	func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
		guard viewController == self else {
			return
		}

		for row in bridgesSection.allRows as? [ListCheckRow<NETunnelProviderProtocol.Transport>] ?? [] {
			row.value = row.selectableValue == bridgesType ? bridgesType : nil
		}
	}


	// MARK: Actions

	@objc
	func connect() {
		bridgesType = bridgesSection.selectedRow()?.value ?? .direct

        VpnManager.shared.switch(to: bridgesType)

        navigationController?.dismiss(animated: true)
	}

	@objc
	private func cancel() {
		dismiss(animated: true)
	}
}

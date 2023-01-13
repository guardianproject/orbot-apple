//
//  BridgesViewController.swift
//  Orbot
//
//  Created by Benjamin Erhart on 10.01.23.
//  Copyright © 2023 Guardian Project. All rights reserved.
//

import UIKit
import Eureka
import IPtProxyUI

class BridgesViewController: BaseFormViewController, BridgesConfDelegate {

	enum Option: String, CaseIterable {
		case direct = "transport_none"
		case snowflake = "transport_snowflake"
		case snowflakeAmp = "transport_snowflake_amp"
		case request = "request"
		case custom = "transport_custom"

		var localizedDescription: String {
			switch self {
			case .direct:
				return NSLocalizedString("Direct connection to Tor", comment: "")

			case .snowflake:
				return NSLocalizedString("Snowflake", comment: "")

			case .snowflakeAmp:
				return NSLocalizedString("Snowflake (AMP rendezvous)", comment: "")

			case .request:
				return NSLocalizedString("Get a bridge from Tor (Obfs4)", comment: "")

			case .custom:
				return NSLocalizedString("Custom bridge", comment: "")
			}
		}

		var longDescription: String {
			switch self {
			case .direct:
				return NSLocalizedString("The best way to connect to Tor. Use if Tor is not blocked.", comment: "")

			case .snowflake, .snowflakeAmp:
				return NSLocalizedString("Connects through Tor volunteers. Gets around some Tor blocking.", comment: "")

			case .request:
				return NSLocalizedString("Cloaks your traffic. Gets around some Tor blocking.", comment: "")

			case .custom:
				return NSLocalizedString("Most likely to keep you connected if Tor is severly blocked. Requires a bridge address from someone you trust.", comment: "")
			}
		}

		var isOn: Bool {
			switch self {
			case .direct:
				return Settings.transport == .none

			case .snowflake:
				return Settings.transport == .snowflake

			case .snowflakeAmp:
				return Settings.transport == .snowflakeAmp

			case .request:
				return false

			case .custom:
				return Settings.transport == .custom
			}
		}
	}

	var transport: IPtProxyUI.Transport {
		get {
			Settings.transport
		}
		set {
			Settings.transport = newValue
		}
	}

	var customBridges: [String]? {
		get {
			Settings.customBridges
		}
		set {
			Settings.customBridges = newValue
		}
	}

	private let section = SelectableSection<ListCheckRow<Option>>(nil, selectionType: .singleSelection(enableDeselection: false))


	override func viewDidLoad() {
		super.viewDidLoad()

		tableView.separatorStyle = .none

		navigationItem.title = NSLocalizedString("Choose How to Connect", comment: "")

		section.onSelectSelectableRow = { [weak self] _, row in
			guard let self = self else {
				return
			}

			// Needed, otherwise rows don't get resized due to changing subtitle.
			self.tableView.reloadData()
		}

		form
		+++ section

		for option in Option.allCases {
			form.last!
			<<< ListCheckRow<Option>() {
				$0.cellStyle = .subtitle
				$0.title = option.localizedDescription

				$0.selectableValue = option
				$0.value = option.isOn ? $0.selectableValue : nil

				$0.cell.accessibilityIdentifier = option.rawValue
				$0.cell.detailTextLabel?.numberOfLines = 0
				$0.cell.backgroundColor = .init(named: .colorBlack2)
			}
			.cellUpdate({ cell, row in
				cell.detailTextLabel?.text = row.value != nil ? row.selectableValue?.longDescription : nil
			})
		}

		form
		+++ RoundedButtonRow()
		.cellUpdate({ [weak self] _, row in
			switch self?.section.selectedRow()?.value ?? .direct {
			case .request, .custom:
				row.title = NSLocalizedString("Next", comment: "")

			default:
				row.title = NSLocalizedString("Save", comment: "")
			}
		})
		.onCellSelection({ [weak self] cell, row in
			switch self?.section.selectedRow()?.value ?? .direct {
			case .request:
				let vc = MoatViewController()
				vc.delegate = self
				self?.navigationController?.pushViewController(vc, animated: true)

			case .custom:
				let vc = CustomBridgesViewController()
				vc.delegate = self
				self?.navigationController?.pushViewController(vc, animated: true)

			default:
				self?.save()
			}
		})
	}

	@objc
	func save() {
		Settings.smartConnect = false

		switch section.selectedRow()?.value ?? .direct {
		case .direct:
			Settings.transport = .none

		case .snowflake:
			Settings.transport = .snowflake

		case .snowflakeAmp:
			Settings.transport = .snowflakeAmp

		case .request, .custom:
			Settings.transport = .custom
		}

		navigationController?.dismiss(animated: true)

		VpnManager.shared.configChanged()

		NotificationCenter.default.post(name: .vpnStatusChanged, object: nil)
	}
}

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
import MessageUI

class BridgesViewController: BaseFormViewController, BridgesConfDelegate, MFMailComposeViewControllerDelegate {

	enum Option: String, CaseIterable {
		case direct = "transport_none"
		case obfs4 = "transport_obfs4"
		case snowflake = "transport_snowflake"
		case snowflakeAmp = "transport_snowflake_amp"
		case request = "request"
		case requestMail = "request_mail"
		case requestTelegram = "request_telegram"
		case custom = "transport_custom"

		var localizedDescription: String {
			switch self {
			case .direct:
				return NSLocalizedString("Direct connection to Tor", comment: "")

			case .obfs4:
				return NSLocalizedString("Well-known Obfs4 bridges", comment: "")

			case .snowflake:
				return NSLocalizedString("Snowflake", comment: "")

			case .snowflakeAmp:
				return NSLocalizedString("Snowflake (AMP rendezvous)", comment: "")

			case .request:
				return NSLocalizedString("Get bridges from Tor (Obfs4)", comment: "")

			case .requestMail:
				return NSLocalizedString("Get bridges via Mail", comment: "")

			case .requestTelegram:
				return NSLocalizedString("Get bridges via Telegram", comment: "")

			case .custom:
				return NSLocalizedString("Custom bridges", comment: "")
			}
		}

		var longDescription: String {
			switch self {
			case .direct:
				return NSLocalizedString("The best way to connect to Tor. Use if Tor is not blocked.", comment: "")

			case .obfs4:
				return NSLocalizedString("Blocked in some countries, but great otherwise when you don't trust the network you're in.", comment: "")

			case .snowflake:
				return NSLocalizedString("Connects through Tor volunteers. Gets around some Tor blocking.", comment: "")

			case .snowflakeAmp:
				return NSLocalizedString("Find Snowflake volunteers through another mechanism.", comment: "")

			case .request:
				return NSLocalizedString("Cloaks your traffic. Gets around some Tor blocking.", comment: "")

			case .requestMail:
				return NSLocalizedString("In case you cannot reach Tor's bridge distribution website, you can try via mail. Has to be from a Gmail or Riseup account.", comment: "")

			case .requestTelegram:
				return NSLocalizedString("If Telegram works for you, you can ask the Telgram Tor Bot for bridges. Tap on 'Start' or write '/start' or '/bridges' in the chat.", comment: "")

			case .custom:
				return NSLocalizedString("Most likely to keep you connected if Tor is severly blocked. Requires a bridge address from someone you trust.", comment: "")
			}
		}

		var isOn: Bool {
			switch self {
			case .direct:
				return Settings.transport == .none

			case .obfs4:
				return Settings.transport == .obfs4

			case .snowflake:
				return Settings.transport == .snowflake

			case .snowflakeAmp:
				return Settings.transport == .snowflakeAmp

			case .custom:
				return Settings.transport == .custom

			default:
				return false
			}
		}

		var isEnabled: Bool {
			switch self {
			case .requestMail:
#if DEBUG
				return Config.screenshotMode || MFMailComposeViewController.canSendMail()
#else
				return MFMailComposeViewController.canSendMail()
#endif

			case .requestTelegram:
#if DEBUG
				return Config.screenshotMode || UIApplication.shared.canOpenURL(Constants.telegramBot)
#else
				return UIApplication.shared.canOpenURL(Constants.telegramBot)
#endif

			default:
				return true
			}
		}
	}

	var transport: Transport = .none

	var customBridges: [String]? = nil

	private let section = SelectableSection<ListCheckRow<Option>>(nil, selectionType: .singleSelection(enableDeselection: false))


	override func viewDidLoad() {
		super.viewDidLoad()

		transport = Settings.transport
		customBridges = Settings.customBridges

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

		for option in Option.allCases.filter({ $0.isEnabled }) {
			form.last!
			<<< ListCheckRow<Option>() {
				$0.cellStyle = .subtitle
				$0.title = option.localizedDescription

				$0.selectableValue = option
				$0.value = option.isOn ? $0.selectableValue : nil

				$0.cell.accessibilityIdentifier = option.rawValue
				$0.cell.detailTextLabel?.numberOfLines = 0
				$0.cell.backgroundColor = .black2
			}
			.cellUpdate({ cell, row in
				cell.detailTextLabel?.text = row.value != nil ? row.selectableValue?.longDescription : nil
			})
		}

		form
		+++ RoundedButtonRow() {
			$0.cell.accessibilityIdentifier = "next_button"
		}
		.cellUpdate({ [weak self] _, row in
			switch self?.section.selectedRow()?.value ?? .direct {
			case .request, .requestMail, .requestTelegram, .custom:
				row.title = NSLocalizedString("Next", comment: "")

			default:
				row.title = IPtProxyUI.L10n.save
			}
		})
		.onCellSelection({ [weak self] cell, row in
			switch self?.section.selectedRow()?.value ?? .direct {
			case .request:
				let vc =  CaptchaViewController.make()
				vc.delegate = self

				self?.navigationController?.pushViewController(vc, animated: true)

			case .requestMail:
				let vc = MFMailComposeViewController()
				vc.mailComposeDelegate = self
				vc.setToRecipients([Constants.emailRecipient])
				vc.setSubject(Constants.emailSubjectAndBody)
				vc.setMessageBody(Constants.emailSubjectAndBody, isHTML: false)

				self?.present(vc, animated: true)

			case .requestTelegram:
				UIApplication.shared.open(Constants.telegramBot) { success in
					guard success else {
						return
					}

					self?.pushCustomBridgesVc()
				}

			case .custom:
				self?.pushCustomBridgesVc()

			default:
				switch self?.section.selectedRow()?.value ?? .direct {
				case .direct:
					self?.transport = .none

				case .obfs4:
					self?.transport = .obfs4

				case .snowflake:
					self?.transport = .snowflake

				case .snowflakeAmp:
					self?.transport = .snowflakeAmp

				default:
					break
				}

				self?.save()
			}
		})
	}

	@objc
	func save() {
		Settings.smartConnect = false
		Settings.transport = transport
		Settings.customBridges = customBridges

		navigationController?.dismiss(animated: true)

		VpnManager.shared.configChanged()

		NotificationCenter.default.post(name: .vpnStatusChanged, object: nil)
	}


	// MARK: MFMailComposeViewControllerDelegate

	public func mailComposeController(_ controller: MFMailComposeViewController,
									  didFinishWith result: MFMailComposeResult,
									  error: Error?)
	{
		controller.dismiss(animated: true) { [weak self] in
			guard let self = self else {
				return
			}

			switch result {
			case .saved, .sent:
				self.pushCustomBridgesVc()

			case .failed:
				AlertHelper.present(self, message: error?.localizedDescription)

			default:
				break
			}
		}
	}


	// MARK: Private Methods

	private func pushCustomBridgesVc() {
		let vc = CustomBridgesViewController.make()
		vc.delegate = self

		navigationController?.pushViewController(vc, animated: true)
	}
}

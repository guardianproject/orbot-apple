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
import ProgressHUD

class BridgesViewController: BaseFormViewController, BridgesConfDelegate, MFMailComposeViewControllerDelegate {

	enum Option: String, CaseIterable {
		case direct = "transport_none"
		case snowflake = "transport_snowflake"
		case snowflakeAmp = "transport_snowflake_amp"
		case requestTelegram = "request_telegram"
		case obfs4 = "transport_obfs4"
		case requestMail = "request_mail"
		case meek = "transport_meek_azure"
		case custom = "transport_custom"

		static func from(_ transport: Transport) -> Option {
			switch transport {
			case .none:
				return .direct

			case .snowflake:
				return .snowflake

			case .snowflakeAmp:
				return .snowflakeAmp

			case .meek:
				return .meek

			case .custom:
				return .custom

			default:
				return .obfs4
			}
		}

		var localizedDescription: String {
			switch self {
			case .direct:
				return NSLocalizedString("Direct Connection", comment: "")

			case .snowflake:
				return NSLocalizedString("Snowflake (original)", comment: "")

			case .snowflakeAmp:
				return NSLocalizedString("Snowflake (AMP)", comment: "")

			case .requestTelegram:
				return NSLocalizedString("Bridges from Tor (obfs4) via Telegram", comment: "")

			case .obfs4:
				return NSLocalizedString("Built-in Bridges (obfs4)", comment: "")

			case .requestMail:
				return NSLocalizedString("Bridges from Tor (obfs4) via Email", comment: "")

			case .meek:
				return NSLocalizedString("Meek", comment: "")

			case .custom:
				return NSLocalizedString("Custom Bridges", comment: "")
			}
		}

		var longDescription: String {
			switch self {
			case .direct:
				return NSLocalizedString(
					"The best way to connect to Tor. Use if Tor is not blocked.",
					comment: "")

			case .snowflake:
				return NSLocalizedString(
					"Connects through Tor volunteers. Gets around some Tor blocking.",
					comment: "")

			case .snowflakeAmp:
				return NSLocalizedString(
					"Connects through Tor volunteers. But uses a different method than 'original' to find the first volunteer. Gets around some Tor blocking.",
					comment: "")

			case .requestTelegram:
				return String(format: NSLocalizedString(
					"Likely to keep you connected if Tor is severely blocked. Using this method will launch the Tor Bot Telegram channel. Tap 'Start' or write '%1$@' in the chat to get bridge addresses.",
					comment: ""), "/start")

			case .obfs4:
				return NSLocalizedString(
					"Cloaks your traffic. Gets around some Tor blocking. Good if you're on public WiFi, but in a country where Tor isn't blocked.",
					comment: "")

			case .requestMail:
				return NSLocalizedString(
					"Cloaks your traffic. Gets around some Tor blocking. Requires an email sent from a Gmail or Riseup account.",
					comment: "")

			case .meek:
				return NSLocalizedString(
					"Cloaks your traffic. Gets around some Tor blocking. May be very slow.",
					comment: "")

			case .custom:
				return NSLocalizedString(
					"Ask within your trusted networks and organizations to see if anyone is hosting a bridge. If not, a friend can get bridges for you.",
					comment: "")
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

			case .meek:
				return Settings.transport == .meek

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

	var transport: Transport = .none {
		didSet {
			if let row = form.rowBy(tag: Option.from(transport).rawValue) as? ListCheckRow<Option>, row.value == nil {
				DispatchQueue.main.async { [weak self] in
					for row in self?.section.allRows ?? [] {
						(row as? ListCheckRow<Option>)?.value = nil
					}

					row.value = row.selectableValue

					// Needed, otherwise rows don't get resized due to changing subtitle.
					self?.tableView.reloadData()
				}
			}
		}
	}

	var customBridges: [String]? = nil

	private let section = SelectableSection<ListCheckRow<Option>>(nil, selectionType: .singleSelection(enableDeselection: false))


	override func viewDidLoad() {
		super.viewDidLoad()

		transport = Settings.transport
		customBridges = Settings.customBridges

		tableView.separatorStyle = .none

		navigationItem.title = L10n.chooseHowToConnect

		section.onSelectSelectableRow = { [weak self] _, row in
			guard let self = self else {
				return
			}

			// Needed, otherwise rows don't get resized due to changing subtitle.
			self.tableView.reloadData()
		}

		form
		+++ RoundedButtonRow() {
			$0.label = NSLocalizedString("Not sure?", comment: "")
			$0.title = NSLocalizedString("Ask Tor", comment: "")
			$0.color = .black3
			$0.backgroundColor = .widgetBackground
			$0.height = 32
			$0.topBottomPadding = 8
		}
		.onCellSelection({ [weak self] cell, row in
			guard let self = self else {
				return
			}

			ProgressHUD.animate()

			AutoConf(self).do(cannotConnectWithoutPt: true) { [weak self] error in
				guard let self = self else {
					return
				}

				DispatchQueue.main.async {
					ProgressHUD.dismiss()

					if let error = error {
						AlertHelper.present(self, message: error.localizedDescription)
					}
					else {
						row.title = nil
						row.attributedTitle = NSAttributedString(string: Option.from(self.transport).localizedDescription, attributes: [.foregroundColor: UIColor.label])
						row.image = .init(systemName: "checkmark")
						row.tintColor = .systemGreen
						row.updateCell()

						DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
							row.title = NSLocalizedString("Ask Tor", comment: "")
							row.attributedTitle = nil
							row.image = nil
							row.tintColor = .label
							row.updateCell()
						}
					}
				}
			}
		})

		+++ section

		for option in Option.allCases.filter({ $0.isEnabled }) {
			form.last!
			<<< ListCheckRow<Option>(option.rawValue) {
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
			case .requestMail, .requestTelegram, .custom:
				row.title = NSLocalizedString("Next", comment: "")

			default:
				row.title = IPtProxyUI.L10n.save
			}
		})
		.onCellSelection({ [weak self] cell, row in
			switch self?.section.selectedRow()?.value ?? .direct {
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

				case .meek:
					self?.transport = .meek

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

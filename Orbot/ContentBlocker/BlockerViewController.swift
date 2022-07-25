//
//  BlockerViewController.swift
//  Orbot
//
//  Created by Benjamin Erhart on 12.04.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import UIKit
import Eureka
import IPtProxyUI

protocol BlockerViewControllerDelegate: AnyObject {

	func update(_ index: Int)
}

class BlockerViewController: BaseFormViewController {

	let index: Int

	var blocker: BlockItem {
		get {
			BlockList.shared[index]
		}
		set {
			BlockList.shared[index] = newValue
		}
	}

	weak var delegate: BlockerViewControllerDelegate?

	init(index: Int) {
		self.index = index

		super.init(style: .grouped)
	}

	required init?(coder: NSCoder) {
		index = coder.decodeInteger(forKey: "index")

		super.init(coder: coder)
	}

	override func encode(with coder: NSCoder) {
		coder.encode(index, forKey: "index")
		coder.encode(blocker, forKey: "blocker")

		super.encode(with: coder)
	}


	private let hiddenWhenAllDomains = Condition.function(["allDomains"], { form in
		return form.rowBy(tag: "allDomains")?.value ?? false
	})

	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.leftBarButtonItem = nil
		navigationItem.title = NSLocalizedString("Blocker", comment: "")

		form
		+++ Section(NSLocalizedString("__BLOCKER_HEADER_1__", comment: "").nilOnEmpty)
		<<< SegmentedRow<BlockAction.BlockType>() {
			$0.options = [.block, .blockCookies]
			$0.value = blocker.action.type
		}
		.onChange({ [weak self] row in
			self?.blocker.action.type = row.value ?? .block
		})

		+++ Section(NSLocalizedString("__BLOCKER_HEADER_2__", comment: "").nilOnEmpty)
		<<< SegmentedRow<BlockTrigger.LoadType>() {
			$0.options = BlockTrigger.LoadType.allCases
			$0.value = blocker.trigger.loadType?.first ?? .all
		}
		.onChange({ [weak self] row in
			let value: [BlockTrigger.LoadType]?

			switch row.value {
			case .none, .all:
				value = nil

			default:
				value = [row.value!]
			}

			self?.blocker.trigger.loadType = value
		})

		+++ SelectableSection<ListCheckRow<BlockTrigger.ResourceType>>(
			NSLocalizedString("__BLOCKER_HEADER_3__", comment: "").nilOnEmpty,
			selectionType: .multipleSelection)

		for type in BlockTrigger.ResourceType.allCases {
			form.last! <<< ListCheckRow<BlockTrigger.ResourceType>(type.rawValue) { row in
				row.title = type.description
				row.selectableValue = type
				row.value = (blocker.trigger.resourceType?.contains(type) ?? false) ? type : nil
			}
			.onChange({ [weak self] row in
				if let value = row.value {
					if self?.blocker.trigger.resourceType == nil {
						self?.blocker.trigger.resourceType = [value]
					}
					else if !(self?.blocker.trigger.resourceType?.contains(value) ?? false) {
						self?.blocker.trigger.resourceType?.append(value)
					}
				}
				else {
					self?.blocker.trigger.resourceType?.removeAll(where: { $0 == row.selectableValue })
				}
			})
		}

		form
		+++ Section(NSLocalizedString("__BLOCKER_HEADER_4__", comment: "").nilOnEmpty)

		<<< SwitchRow("allDomains") {
			$0.title = NSLocalizedString("all domains", comment: "")
			$0.value = blocker.trigger.ifDomain?.isEmpty ?? true && blocker.trigger.unlessDomain?.isEmpty ?? true
		}
		.onChange({ [weak self] row in
			if row.value ?? false {
				self?.blocker.trigger.ifDomain = nil
				self?.blocker.trigger.unlessDomain = nil
			}
		})

		<<< SwitchRow("allDomainsBut") {
			$0.title = NSLocalizedString("all domains but", comment: "")
			$0.value = !(blocker.trigger.unlessDomain?.isEmpty ?? true)

			$0.hidden = hiddenWhenAllDomains
		}
		.onChange({ [weak self] row in
			if row.value ?? false {
				self?.blocker.trigger.unlessDomain = self?.blocker.trigger.ifDomain
				self?.blocker.trigger.ifDomain = nil
			}
			else {
				self?.blocker.trigger.ifDomain = self?.blocker.trigger.unlessDomain
				self?.blocker.trigger.unlessDomain = nil
			}
		})

		<<< LabelRow() {
			$0.title = NSLocalizedString("selected domains", comment: "")

			$0.hidden = hiddenWhenAllDomains
		}

		<<< TextAreaRow() {
			$0.placeholder = "example.com example.org *example.gov"
			$0.value = blocker.trigger.ifDomain?.isEmpty ?? true
				? blocker.trigger.unlessDomain?.joined(separator: " ")
				: blocker.trigger.ifDomain?.joined(separator: " ")

			$0.turnOffAutoCorrect()

			$0.hidden = hiddenWhenAllDomains
		}
		.onChange({ [weak self] row in
			let value: [String]? = row.value?
				.components(separatedBy: .whitespacesAndNewlines)
				.compactMap({
					let d = $0.trimmingCharacters(in: .whitespacesAndNewlines)

					return d.isEmpty ? nil : d
				})

			if self?.form.rowBy(tag: "allDomainsBut")?.value ?? false {
				self?.blocker.trigger.unlessDomain = value
			}
			else {
				self?.blocker.trigger.ifDomain = value
			}
		})

		<<< LabelRow() {
			$0.value = NSLocalizedString("Prefix with asterisk (*) to also capture subdomains.", comment: "")

			$0.cellStyle = .subtitle
			$0.cell.detailTextLabel?.numberOfLines = 0

			$0.hidden = hiddenWhenAllDomains
		}

		+++ Section(NSLocalizedString("__BLOCKER_HEADER_5__", comment: "").nilOnEmpty)

		<<< SwitchRow("anything") {
			$0.title = NSLocalizedString("anything", comment: "")
			$0.value = blocker.trigger.urlFilter.isEmpty || blocker.trigger.urlFilter == ".*"
		}
		.onChange({ [weak self] row in
			if row.value ?? false {
				self?.blocker.trigger.urlFilter = ".*"
			}
		})

		<<< TextRow() {
			$0.title = NSLocalizedString("this regex:", comment: "")
			$0.value = blocker.trigger.urlFilter
			$0.turnOffAutoCorrect()

			$0.hidden = Condition.function(["anything"], { form in
				return form.rowBy(tag: "anything")?.value ?? false
			})
		}
		.onChange({ [weak self] row in
			self?.blocker.trigger.urlFilter = row.value ?? ".*"
		})
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		delegate?.update(index)
	}
}

//
//  RoundedButtonRow.swift
//  Orbot
//
//  Created by Benjamin Erhart on 13.01.23.
//  Copyright © 2020 - 2026 Guardian Project. All rights reserved.
//

import Eureka

/**
 Eureka button row with rounded corners and leading and trailing padding using a `UIButton` for the actual functionality.
 */
class RoundedButtonCell: ButtonCellOf<String> {

	private lazy var button: UIButton = {
		let button = UIButton(type: .system)

		button.translatesAutoresizingMaskIntoConstraints = false
		button.titleLabel?.allowsDefaultTighteningForTruncation = true
		button.titleLabel?.adjustsFontSizeToFitWidth = true
		button.titleLabel?.minimumScaleFactor = 0.5
		button.configuration = .bordered()

		return button
	}()

	private lazy var label: UILabel = {
		let label = UILabel(frame: .zero)

		label.translatesAutoresizingMaskIntoConstraints = false
		label.adjustsFontSizeToFitWidth = true
		label.minimumScaleFactor = 0.5
		label.allowsDefaultTighteningForTruncation = true

		return label
	}()

	override func setup() {
		super.setup()

		contentView.addSubview(button)

		let row = row as? RoundedButtonRow

		let ltp = row?.leadingTrailingPadding ?? 16
		let tbp = row?.topBottomPadding ?? 0

		if !(row?.label?.isEmpty ?? true) {
			contentView.addSubview(label)

			label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ltp).isActive = true
			label.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
			label.trailingAnchor.constraint(lessThanOrEqualTo: button.leadingAnchor, constant: -ltp).isActive = true
		}
		else {
			button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ltp).isActive = true
		}

		button.heightAnchor.constraint(equalToConstant: row?.height ?? 48).isActive = true
		button.topAnchor.constraint(equalTo: contentView.topAnchor, constant: tbp).isActive = true
		button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ltp).isActive = true
		button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -tbp).isActive = true

		button.addTarget(self, action: #selector(tapped), for: .touchUpInside)
	}

	override func update() {
		button.setTitle(row.title)

		let row = row as? RoundedButtonRow

		label.text = row?.label

		button.setAttributedTitle(row?.attributedTitle)
		button.configuration?.image = row?.image
		button.configuration?.background.cornerRadius = row?.cornerRadius ?? 9
		button.configuration?.background.backgroundColor = row?.color
		button.tintColor = row?.tintColor

		backgroundColor = row?.backgroundColor
	}

	@objc
	private func tapped() {
		row.didSelect()
	}
}

final class RoundedButtonRow: Row<RoundedButtonCell>, RowType {

	var attributedTitle: NSAttributedString?

	var label: String?

	var image: UIImage?

	var color: UIColor = .accent

	var backgroundColor: UIColor = .black2

	var tintColor: UIColor = .label

	var height: CGFloat = 48

	var cornerRadius: CGFloat = 9

	var leadingTrailingPadding: CGFloat = 16

	var topBottomPadding: CGFloat = 0


	convenience init(
		tag: String? = nil,
		_ initializer: (RoundedButtonRow) -> Void = { _ in })
	{
		self.init(tag: tag)

		initializer(self)
	}

	required init(tag: String?) {
		super.init(tag: tag)

		displayValueFor = nil
		cellStyle = .default
	}
}


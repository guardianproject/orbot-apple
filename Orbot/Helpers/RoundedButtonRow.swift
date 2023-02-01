//
//  RoundedButtonRow.swift
//  Orbot
//
//  Created by Benjamin Erhart on 13.01.23.
//  Copyright © 2023 Guardian Project. All rights reserved.
//

import Eureka

/**
 Eureka button row with rounded corners and leading and trailing padding using a `UIButton` for the actual functionality.
 */
class RoundedButtonCell: ButtonCellOf<String> {

	private lazy var button: UIButton = {
		let button = UIButton(type: .system)

		button.translatesAutoresizingMaskIntoConstraints = false

		button.backgroundColor = .init(named: .colorAccent1)

		return button
	}()

	override func setup() {
		super.setup()

		contentView.addSubview(button)

		let row = row as? RoundedButtonRow

		let ltp = row?.leadingTrailingPadding ?? 16
		let tbp = row?.topBottomPadding ?? 0

		button.heightAnchor.constraint(equalToConstant: row?.height ?? 48).isActive = true
		button.topAnchor.constraint(equalTo: contentView.topAnchor, constant: tbp).isActive = true
		button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ltp).isActive = true
		button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ltp).isActive = true
		button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -tbp).isActive = true

		button.layer.cornerRadius = row?.cornerRadius ?? 9

		button.addTarget(self, action: #selector(tapped), for: .touchUpInside)

		backgroundColor = .init(named: .colorBlack2)
	}

	override func update() {
		button.setTitle(row.title)
	}

	@objc
	private func tapped() {
		row.didSelect()
	}
}

final class RoundedButtonRow: Row<RoundedButtonCell>, RowType {

	fileprivate var height: CGFloat = 48

	fileprivate var cornerRadius: CGFloat = 9

	fileprivate var leadingTrailingPadding: CGFloat = 16

	fileprivate var topBottomPadding: CGFloat = 0


	convenience init(tag: String?, height: CGFloat = 48, cornerRadius: CGFloat = 9, leadingTrailingPadding: CGFloat = 16, topBottomPadding: CGFloat = 0) {
		self.init(tag: tag)

		self.height = height
		self.cornerRadius = cornerRadius
		self.leadingTrailingPadding = leadingTrailingPadding
		self.topBottomPadding = topBottomPadding
	}

	required init(tag: String?) {
		super.init(tag: tag)

		displayValueFor = nil
		cellStyle = .default
	}
}


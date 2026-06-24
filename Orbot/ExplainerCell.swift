//
//  ExplainerCell.swift
//  Orbot
//
//  Created by Benjamin Erhart on 23.06.26.
//  Copyright © 2026 Guardian Project. All rights reserved.
//

import UIKit

class ExplainerCell: UITableViewCell {

	@IBOutlet weak var iconIv: UIImageView!

	@IBOutlet weak var textLb: UILabel!


	func set(icon: UIImage?, text: String?) -> Self {
		iconIv.image = icon
		textLb.text = text

		return self
	}
}

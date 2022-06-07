//
//  ApiAccessCell.swift
//  Orbot
//
//  Created by Benjamin Erhart on 07.06.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import UIKit

class ApiAccessCell: UITableViewCell {

	class var reuseId: String {
		String(describing: self)
	}

	class var nib: UINib {
		UINib(nibName: reuseId, bundle: nil)
	}

	@IBOutlet weak var appIdLb: UILabel?

	@IBOutlet weak var keyLb: UILabel?

	@IBOutlet weak var bypassLb: UILabel?
}
